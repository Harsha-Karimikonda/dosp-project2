-module(project2).
-export([main/1, run/1, run/3, measure_running_time/1]).

run(Args) when is_list(Args) ->
    main(Args).


%% Command-line entry point
main(Args) ->
    case Args of
        [NumNodesArg, TopologyArg, AlgorithmArg] ->
            NumNodes = to_integer(NumNodesArg),
            run(NumNodes, TopologyArg, AlgorithmArg);
        _ ->
            io:format("Usage: project2 numNodes topology algorithm~n"),
            io:format("  numNodes : integer~n"),
            io:format("  topology : full | 2D | line | imp2D~n"),
            io:format("  algorithm: gossip | push-sum~n"),
            halt(1)
    end.

to_integer(X) when is_integer(X) -> X;
to_integer(X) when is_atom(X)    -> list_to_integer(atom_to_list(X));
to_integer(X) when is_list(X)    -> list_to_integer(X).

%% Required timing measurement function from assignment specification
measure_running_time(Fun) ->
    Start = erlang:monotonic_time(microsecond),
    Res = Fun(),
    End = erlang:monotonic_time(microsecond),
    Duration = End - Start,
    {Duration, Res}.

run(NumNodes, TopologyStr, AlgorithmStr) ->
    Topology = normalize_topology(TopologyStr),
    Algorithm = normalize_algorithm(AlgorithmStr),
    AdjustedN = topology:adjust_node_count(Topology, NumNodes),
    if
        AdjustedN =/= NumNodes ->
            io:format("Rounded numNodes from ~p to ~p for 2D-based topology.~n", [NumNodes, AdjustedN]);
        true ->
            ok
    end,

    io:format("Starting simulator with ~p nodes, topology: ~s, algorithm: ~s...~n",
              [AdjustedN, TopologyStr, AlgorithmStr]),

    {Duration, {Status, Details}} = measure_running_time(fun() ->
        start_simulation(AdjustedN, Topology, Algorithm)
    end),

    case Status of
        ok ->
            io:format("Algorithm converged successfully!~n"),
            io:format("Convergence time: ~p microseconds (~.3f ms)~n",
                      [Duration, Duration / 1000.0]);
        timeout ->
            io:format("Simulation timed out without reaching convergence.~nDetails: ~p~n", [Details]);
        error ->
            io:format("Simulation failed: ~p~n", [Details])
    end,
    halt(0).

normalize_topology(T) when is_atom(T) -> normalize_topology(atom_to_list(T));
normalize_topology("full")  -> full;
normalize_topology("line")  -> line;
normalize_topology("2D")    -> '2D';
normalize_topology("2d")    -> '2D';
normalize_topology("imp2D") -> imp2D;
normalize_topology("imp2d") -> imp2D;
normalize_topology(Other)   -> list_to_atom(Other).

normalize_algorithm(A) when is_atom(A) -> normalize_algorithm(atom_to_list(A));
normalize_algorithm("gossip")   -> gossip;
normalize_algorithm("push-sum") -> push_sum;
normalize_algorithm("push_sum") -> push_sum;
normalize_algorithm(Other)      -> list_to_atom(Other).

start_simulation(N, Topology, Algorithm) ->
    MasterPid = self(),

    %% 1. Spawn worker actors
    WorkerPids =
        case Algorithm of
            gossip ->
                [worker:start_gossip(I, Topology, N, MasterPid) || I <- lists:seq(1, N)];
            push_sum ->
                [worker:start_push_sum(I, Topology, N, MasterPid) || I <- lists:seq(1, N)]
        end,

    %% 2. Register workers tuple for fast O(1) concurrent lookup
    WorkersTuple = list_to_tuple(WorkerPids),
    persistent_term:put(workers, WorkersTuple),

    %% 3. Initialize neighbor lists for all workers
    lists:foreach(fun(I) ->
        Pid = element(I, WorkersTuple),
        Neighbors = topology:get_neighbors(Topology, I, N),
        Pid ! {init_neighbors, Neighbors}
    end, lists:seq(1, N)),

    %% 4. Trigger starting participant
    StartPid = element(1, WorkersTuple),
    case Algorithm of
        gossip ->
            StartPid ! {rumor, "UF_COP5612_GOSSIP_FACT"};
        push_sum ->
            StartPid ! start
    end,

    %% 5. Await convergence
    Result =
        case Algorithm of
            gossip ->
                wait_gossip_convergence(N, 0, 0);
            push_sum ->
                wait_push_sum_convergence(N, 0)
        end,

    %% 6. Clean up
    lists:foreach(fun(Pid) -> Pid ! stop end, WorkerPids),
    persistent_term:erase(workers),
    Result.

%% Gossip converges when every node has heard the rumor at least once.
%% Each worker independently stops transmitting after its tenth receipt.
wait_gossip_convergence(Total, HeardCount, TerminatedCount) ->
    receive
        {node_heard, _Id} ->
            NewHeard = HeardCount + 1,
            if
                NewHeard >= Total ->
                    {ok, {heard_all, Total}};
                true ->
                    wait_gossip_convergence(Total, NewHeard, TerminatedCount)
            end;
        {node_terminated, _Id} ->
            wait_gossip_convergence(Total, HeardCount, TerminatedCount + 1)
    after 180000 -> %% 3-minute timeout safety
        {timeout, {heard, HeardCount, terminated, TerminatedCount, total, Total}}
    end.

%% Wait for push-sum convergence: when all N nodes achieve ratio stability
wait_push_sum_convergence(Total, TerminatedCount) ->
    receive
        {node_terminated, _Id, _Ratio} ->
            NewTerminated = TerminatedCount + 1,
            if
                NewTerminated >= Total ->
                    {ok, {all_converged, Total}};
                true ->
                    wait_push_sum_convergence(Total, NewTerminated)
            end
    after 180000 -> %% 3-minute timeout safety
        {timeout, {terminated, TerminatedCount, total, Total}}
    end.
