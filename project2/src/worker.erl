-module(worker).
-export([start_gossip/4, start_push_sum/4]).

%% ---------------------------------------------------------
%% Gossip Worker
%% ---------------------------------------------------------
start_gossip(Id, Topology, NumNodes, MasterPid) ->
    spawn(fun() ->
        receive
            {init_neighbors, Neighbors} ->
                gossip_loop(Id, Topology, NumNodes, Neighbors, 0, MasterPid, false, undefined)
        end
    end).

gossip_loop(Id, Topology, NumNodes, Neighbors, RumorCount, MasterPid, Terminated, RumorMsg) ->
    receive
        {rumor, Msg} ->
            NewCount = RumorCount + 1,
            %% If hearing rumor for the first time
            case RumorCount of
                0 ->
                    MasterPid ! {node_heard, Id},
                    send_rumor_to_neighbor(Id, Topology, NumNodes, Neighbors, Msg),
                    erlang:send_after(10, self(), gossip_tick);
                _ ->
                    ok
            end,

            %% Check termination condition: heard rumor 10 times
            NewTerminated =
                if
                    NewCount >= 10 andalso (not Terminated) ->
                        MasterPid ! {node_terminated, Id},
                        true;
                    true ->
                        Terminated
                end,
            gossip_loop(Id, Topology, NumNodes, Neighbors, NewCount, MasterPid, NewTerminated, Msg);

        gossip_tick ->
            case RumorCount < 10 of
                true ->
                    send_rumor_to_neighbor(Id, Topology, NumNodes, Neighbors, RumorMsg),
                    erlang:send_after(10, self(), gossip_tick);
                false ->
                    ok
            end,
            gossip_loop(Id, Topology, NumNodes, Neighbors, RumorCount, MasterPid, Terminated, RumorMsg);

        stop ->
            exit(normal)
    end.

send_rumor_to_neighbor(Id, Topology, NumNodes, Neighbors, Msg) ->
    NeighborId = topology:pick_random_neighbor(Topology, Id, NumNodes, Neighbors),
    case NeighborId =/= Id of
        true ->
            Workers = persistent_term:get(workers),
            NeighborPid = element(NeighborId, Workers),
            NeighborPid ! {rumor, Msg};
        false ->
            ok
    end.

%% ---------------------------------------------------------
%% Push-Sum Worker
%% ---------------------------------------------------------
start_push_sum(Id, Topology, NumNodes, MasterPid) ->
    spawn(fun() ->
        receive
            {init_neighbors, Neighbors} ->
                %% Initial state: s = i, w = 1
                S = float(Id),
                W = 1.0,
                push_sum_loop(Id, Topology, NumNodes, Neighbors, S, W, 0, MasterPid, false)
        end
    end).

push_sum_loop(Id, Topology, NumNodes, Neighbors, S, W, Streak, MasterPid, Terminated) ->
    receive
        start ->
            %% Divide s and w in half, send to a random neighbor
            S_half = S / 2.0,
            W_half = W / 2.0,
            send_push_sum(Id, Topology, NumNodes, Neighbors, S_half, W_half),
            push_sum_loop(Id, Topology, NumNodes, Neighbors, S_half, W_half, Streak, MasterPid, Terminated);

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

            NewTerminated =
                if
                    NewStreak >= 3 andalso (not Terminated) ->
                        MasterPid ! {node_terminated, Id, NewRatio},
                        true;
                    true ->
                        Terminated
                end,

            %% Halve s and w, keep half, send half to random neighbor
            S_send = NewS / 2.0,
            W_send = NewW / 2.0,
            send_push_sum(Id, Topology, NumNodes, Neighbors, S_send, W_send),
            push_sum_loop(Id, Topology, NumNodes, Neighbors, S_send, W_send, NewStreak, MasterPid, NewTerminated);

        stop ->
            exit(normal)
    end.

send_push_sum(Id, Topology, NumNodes, Neighbors, S, W) ->
    NeighborId = topology:pick_random_neighbor(Topology, Id, NumNodes, Neighbors),
    case NeighborId =/= Id of
        true ->
            Workers = persistent_term:get(workers),
            NeighborPid = element(NeighborId, Workers),
            NeighborPid ! {push_sum, S, W};
        false ->
            ok
    end.

