-module(worker_bonus).
-export([start_gossip/5, start_push_sum/5]).

%% ---------------------------------------------------------
%% Bonus Gossip Worker (with Node Crash and Connection Loss models)
%% ---------------------------------------------------------
start_gossip(Id, Topology, NumNodes, MasterPid, FailConfig) ->
    spawn(fun() ->
        {FailType, FailRate} = FailConfig,
        %% Evaluate node crash failure model
        IsCrashed = (FailType =:= node_crash andalso rand:uniform() =< FailRate),
        if
            IsCrashed ->
                MasterPid ! {node_failed, Id},
                exit(crashed);
            true ->
                receive
                    {init_neighbors, Neighbors} ->
                        gossip_loop(Id, Topology, NumNodes, Neighbors, 0, MasterPid, false, undefined, FailConfig)
                end
        end
    end).

gossip_loop(Id, Topology, NumNodes, Neighbors, RumorCount, MasterPid, Terminated, RumorMsg, FailConfig) ->
    receive
        {rumor, Msg} ->
            NewCount = RumorCount + 1,
            case RumorCount of
                0 ->
                    MasterPid ! {node_heard, Id},
                    send_rumor_to_neighbor(Id, Topology, NumNodes, Neighbors, Msg, FailConfig),
                    erlang:send_after(10, self(), gossip_tick);
                _ ->
                    %% Each receipt causes another asynchronous gossip step,
                    %% until this actor reaches its termination threshold.
                    case NewCount < 10 of
                        true -> send_rumor_to_neighbor(Id, Topology, NumNodes, Neighbors, Msg, FailConfig);
                        false -> ok
                    end
            end,

            NewTerminated =
                if
                    NewCount >= 10 andalso (not Terminated) ->
                        MasterPid ! {node_terminated, Id},
                        true;
                    true ->
                        Terminated
                end,
            gossip_loop(Id, Topology, NumNodes, Neighbors, NewCount, MasterPid, NewTerminated, Msg, FailConfig);

        gossip_tick ->
            case RumorCount < 10 of
                true ->
                    send_rumor_to_neighbor(Id, Topology, NumNodes, Neighbors, RumorMsg, FailConfig),
                    erlang:send_after(10, self(), gossip_tick);
                false ->
                    ok
            end,
            gossip_loop(Id, Topology, NumNodes, Neighbors, RumorCount, MasterPid, Terminated, RumorMsg, FailConfig);

        stop ->
            exit(normal)
    end.

send_rumor_to_neighbor(Id, Topology, NumNodes, Neighbors, Msg, FailConfig) ->
    {FailType, FailRate} = FailConfig,
    %% Connection loss model: drop message with probability FailRate
    MessageDropped = (FailType =:= connection_loss andalso rand:uniform() =< FailRate),
    case MessageDropped of
        true ->
            ok; %% Message lost due to faulty link
        false ->
            NeighborId = topology:pick_random_neighbor(Topology, Id, NumNodes, Neighbors),
            case NeighborId =/= Id of
                true ->
                    try persistent_term:get(workers) of
                        Workers ->
                            NeighborPid = element(NeighborId, Workers),
                            NeighborPid ! {rumor, Msg}
                    catch
                        _:_ -> ok
                    end;
                false ->
                    ok
            end
    end.

%% ---------------------------------------------------------
%% Bonus Push-Sum Worker
%% ---------------------------------------------------------
start_push_sum(Id, Topology, NumNodes, MasterPid, FailConfig) ->
    spawn(fun() ->
        {FailType, FailRate} = FailConfig,
        IsCrashed = (FailType =:= node_crash andalso rand:uniform() =< FailRate),
        if
            IsCrashed ->
                MasterPid ! {node_failed, Id},
                exit(crashed);
            true ->
                receive
                    {init_neighbors, Neighbors} ->
                        S = float(Id),
                        W = 1.0,
                        push_sum_loop(Id, Topology, NumNodes, Neighbors, S, W, 0, MasterPid, FailConfig)
                end
        end
    end).

push_sum_loop(Id, Topology, NumNodes, Neighbors, S, W, Streak, MasterPid, FailConfig) ->
    receive
        start ->
            S_half = S / 2.0,
            W_half = W / 2.0,
            send_push_sum(Id, Topology, NumNodes, Neighbors, S_half, W_half, FailConfig),
            push_sum_loop(Id, Topology, NumNodes, Neighbors, S_half, W_half, Streak, MasterPid, FailConfig);

        {push_sum, InS, InW} ->
            OldRatio = S / W,
            NewS = S + InS,
            NewW = W + InW,
            NewRatio = NewS / NewW,
            Diff = abs(NewRatio - OldRatio),

            NewStreak =
                if
                    Diff =< 1.0e-10 -> Streak + 1;
                    true -> 0
                end,

            if
                NewStreak >= 3 ->
                    MasterPid ! {node_terminated, Id, NewRatio},
                    S_send = NewS / 2.0,
                    W_send = NewW / 2.0,
                    send_push_sum(Id, Topology, NumNodes, Neighbors, S_send, W_send, FailConfig),
                    push_sum_terminated_loop(Id, Topology, NumNodes, Neighbors, FailConfig);
                true ->
                    S_send = NewS / 2.0,
                    W_send = NewW / 2.0,
                    send_push_sum(Id, Topology, NumNodes, Neighbors, S_send, W_send, FailConfig),
                    push_sum_loop(Id, Topology, NumNodes, Neighbors, S_send, W_send, NewStreak, MasterPid, FailConfig)
            end;

        stop ->
            exit(normal)
    end.

push_sum_terminated_loop(Id, Topology, NumNodes, Neighbors, FailConfig) ->
    receive
        {push_sum, InS, InW} ->
            send_push_sum(Id, Topology, NumNodes, Neighbors, InS, InW, FailConfig),
            push_sum_terminated_loop(Id, Topology, NumNodes, Neighbors, FailConfig);
        stop ->
            exit(normal)
    end.

send_push_sum(Id, Topology, NumNodes, Neighbors, S, W, FailConfig) ->
    {FailType, FailRate} = FailConfig,
    MessageDropped = (FailType =:= connection_loss andalso rand:uniform() =< FailRate),
    case MessageDropped of
        true ->
            ok;
        false ->
            NeighborId = topology:pick_random_neighbor(Topology, Id, NumNodes, Neighbors),
            case NeighborId =/= Id of
                true ->
                    try persistent_term:get(workers) of
                        Workers ->
                            NeighborPid = element(NeighborId, Workers),
                            NeighborPid ! {push_sum, S, W}
                    catch
                        _:_ -> ok
                    end;
                false ->
                    ok
            end
    end.
