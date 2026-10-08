-module(project2_bonus).
-export([main/1, measure_running_time/1]).


main(Args) ->
    case Args of
        [NumNodesArg, TopologyArg, AlgorithmArg] ->
            run(to_integer(NumNodesArg), TopologyArg, AlgorithmArg, node_crash, 0.1);
        [NumNodesArg, TopologyArg, AlgorithmArg, FailParamArg] ->
            run(to_integer(NumNodesArg), TopologyArg, AlgorithmArg, node_crash, to_float(FailParamArg));
        [NumNodesArg, TopologyArg, AlgorithmArg, FailTypeArg, FailParamArg] ->
            run(to_integer(NumNodesArg), TopologyArg, AlgorithmArg, normalize_fail_type(FailTypeArg), to_float(FailParamArg));
        _ ->
            io:format("Usage: project2_bonus numNodes topology algorithm [failType] [failRate]~n"),
            io:format("  failType: node_crash (default) | connection_loss~n"),
            io:format("  failRate: float between 0.0 and 1.0 (default 0.1)~n"),
            halt(1)
    end.

to_integer(X) when is_integer(X) -> X;
to_integer(X) when is_atom(X)    -> list_to_integer(atom_to_list(X));
to_integer(X) when is_list(X)    -> list_to_integer(X).

to_float(X) when is_float(X)   -> X;
to_float(X) when is_integer(X) -> float(X);
to_float(X) when is_atom(X)    -> to_float(atom_to_list(X));
to_float(X) when is_list(X) ->
    case string:to_float(X) of
        {error, no_float} -> float(list_to_integer(X));
        {F, _} -> F
    end.

normalize_fail_type(T) when is_atom(T) -> normalize_fail_type(atom_to_list(T));
normalize_fail_type("node_crash")      -> node_crash;
normalize_fail_type("connection_loss")  -> connection_loss;
normalize_fail_type("node")            -> node_crash;
normalize_fail_type("loss")            -> connection_loss;
normalize_fail_type(Other)             -> list_to_atom(Other).

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

measure_running_time(Fun) ->
    Start = erlang:monotonic_time(microsecond),
    Res = Fun(),
    End = erlang:monotonic_time(microsecond),
    Duration = End - Start,
    {Duration, Res}.

run(NumNodes, TopologyStr, AlgorithmStr, FailType, FailRate) ->
    Topology = normalize_topology(TopologyStr),
    Algorithm = normalize_algorithm(AlgorithmStr),
    AdjustedN = topology:adjust_node_count(Topology, NumNodes),

    io:format("=====================================================~n"),
    io:format("Bonus Failure Simulator~n"),
    io:format("Nodes: ~p, Topology: ~p, Algorithm: ~p~n", [AdjustedN, Topology, Algorithm]),
    io:format("Failure Model: ~p, Failure Rate: ~.2f (~.1f%)~n",
              [FailType, FailRate, FailRate * 100.0]),
    io:format("=====================================================~n"),

    {Duration, {Status, Coverage, ActiveCount, TotalCount}} =
        measure_running_time(fun() ->
            start_simulation(AdjustedN, Topology, Algorithm, {FailType, FailRate})
        end),

    CoveragePct = if ActiveCount > 0 -> (Coverage / ActiveCount) * 100.0; true -> 0.0 end,
    io:format("Result Status : ~p~n", [Status]),
    io:format("Active Nodes  : ~p / ~p~n", [ActiveCount, TotalCount]),
    io:format("Covered Nodes : ~p (~.2f% of active nodes)~n", [Coverage, CoveragePct]),
    io:format("Duration      : ~p microseconds (~.3f ms)~n", [Duration, Duration / 1000.0]),
    halt(0).

start_simulation(N, Topology, Algorithm, FailConfig) ->
    MasterPid = self(),

    %% 1. Spawn workers with failure configuration
    WorkerPids =
        case Algorithm of
            gossip ->
                [worker_bonus:start_gossip(I, Topology, N, MasterPid, FailConfig) || I <- lists:seq(1, N)];
            push_sum ->
                [worker_bonus:start_push_sum(I, Topology, N, MasterPid, FailConfig) || I <- lists:seq(1, N)]
        end,

    WorkersTuple = list_to_tuple(WorkerPids),
    persistent_term:put(workers, WorkersTuple),

    %% 2. Collect initial node crashes
    timer:sleep(20),
    FailedNodes = collect_failed_nodes([]),
    ActiveCount = N - length(FailedNodes),

    %% 3. Initialize neighbors
    lists:foreach(fun(I) ->
        case lists:member(I, FailedNodes) of
            false ->
                Pid = element(I, WorkersTuple),
                Neighbors = topology:get_neighbors(Topology, I, N),
                Pid ! {init_neighbors, Neighbors};
            true ->
                ok
        end
    end, lists:seq(1, N)),

    %% 4. Trigger starting participant (pick first non-failed node)
    FirstAlive = find_first_alive(1, N, FailedNodes),
    case FirstAlive of
        none ->
            lists:foreach(fun(Pid) -> Pid ! stop end, WorkerPids),
            persistent_term:erase(workers),
            {all_failed, 0, 0, N};
        StartId ->
            StartPid = element(StartId, WorkersTuple),
            case Algorithm of
                gossip -> StartPid ! {rumor, "UF_COP5612_BONUS_RUMOR"};
                push_sum -> StartPid ! start
            end,

            %% 5. Await convergence of surviving nodes
            Result =
                case Algorithm of
                    gossip ->
                        wait_gossip_bonus(ActiveCount, 0, 0, 10000);
                    push_sum ->
                        wait_push_sum_bonus(ActiveCount, 0, 15000)
                end,

            lists:foreach(fun(Pid) -> Pid ! stop end, WorkerPids),
            persistent_term:erase(workers),
            case Result of
                {ok, Cov} -> {converged, Cov, ActiveCount, N};
                {partial, Cov} -> {partial_coverage, Cov, ActiveCount, N}
            end
    end.

collect_failed_nodes(Acc) ->
    receive
        {node_failed, Id} ->
            collect_failed_nodes([Id | Acc])
    after 0 ->
        Acc
    end.

find_first_alive(I, N, _Failed) when I > N -> none;
find_first_alive(I, N, Failed) ->
    case lists:member(I, Failed) of
        true -> find_first_alive(I + 1, N, Failed);
        false -> I
    end.

wait_gossip_bonus(ActiveTotal, HeardCount, TerminatedCount, TimeoutMs) ->
    receive
        {node_heard, _Id} ->
            NewHeard = HeardCount + 1,
            if
                NewHeard >= ActiveTotal -> {ok, ActiveTotal};
                true -> wait_gossip_bonus(ActiveTotal, NewHeard, TerminatedCount, TimeoutMs)
            end;
        {node_terminated, _Id} ->
            wait_gossip_bonus(ActiveTotal, HeardCount, TerminatedCount + 1, TimeoutMs)
    after TimeoutMs ->
        {partial, HeardCount}
    end.

wait_push_sum_bonus(ActiveTotal, TermCount, TimeoutMs) ->
    receive
        {node_terminated, _Id, _Ratio} ->
            NewTerm = TermCount + 1,
            if
                NewTerm >= ActiveTotal -> {ok, ActiveTotal};
                true -> wait_push_sum_bonus(ActiveTotal, NewTerm, TimeoutMs)
            end
    after TimeoutMs ->
        {partial, TermCount}
    end.
