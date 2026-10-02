-module(topology).
-export([adjust_node_count/2, get_neighbors/3, pick_random_neighbor/4]).

%% Round up to next perfect square for 2D and imp2D topologies
adjust_node_count(Topology, NumNodes) when Topology =:= "2D"; Topology =:= "imp2D";
                                           Topology =:= '2D'; Topology =:= 'imp2D' ->
    K = math:ceil(math:sqrt(NumNodes)),
    trunc(K * K);
adjust_node_count(_Topology, NumNodes) ->
    NumNodes.

%% Return neighbor list for a given node Id (1-based index)
get_neighbors(Topology, Id, NumNodes) when Topology =:= "line"; Topology =:= line ->
    if
        NumNodes =< 1 -> [];
        Id =:= 1 -> [2];
        Id =:= NumNodes -> [NumNodes - 1];
        true -> [Id - 1, Id + 1]
    end;

get_neighbors(Topology, Id, NumNodes) when Topology =:= "2D"; Topology =:= '2D' ->
    grid_neighbors(Id, NumNodes);

get_neighbors(Topology, Id, NumNodes) when Topology =:= "imp2D"; Topology =:= 'imp2D' ->
    GridNeighbors = grid_neighbors(Id, NumNodes),
    RandomOther = pick_random_other(Id, NumNodes, GridNeighbors),
    [RandomOther | GridNeighbors];

get_neighbors(Topology, _Id, _NumNodes) when Topology =:= "full"; Topology =:= full ->
    %% For full topology, we represent neighbors as 'full' to save memory,
    %% or return empty list here because pick_random_neighbor handles it in O(1).
    full.

%% Grid neighbors for K x K square
grid_neighbors(Id, NumNodes) ->
    K = trunc(math:sqrt(NumNodes)),
    R = (Id - 1) div K,
    C = (Id - 1) rem K,
    Up    = if R > 0     -> [(R - 1) * K + C + 1]; true -> [] end,
    Down  = if R < K - 1 -> [(R + 1) * K + C + 1]; true -> [] end,
    Left  = if C > 0     -> [R * K + (C - 1) + 1]; true -> [] end,
    Right = if C < K - 1 -> [R * K + (C + 1) + 1]; true -> [] end,
    Up ++ Down ++ Left ++ Right.

%% Pick a random other node from 1..NumNodes distinct from Id and existing neighbors
pick_random_other(Id, NumNodes, Neighbors) ->
    Candidate = rand:uniform(NumNodes),
    case Candidate =/= Id andalso not lists:member(Candidate, Neighbors) of
        true -> Candidate;
        false ->
            %% Try again if collision occurs (rare for N >= 9)
            if NumNodes > length(Neighbors) + 1 ->
                pick_random_other(Id, NumNodes, Neighbors);
            true ->
                %% If network is too small, fallback to any other node
                Candidate
            end
    end.

%% Pick a random neighbor efficiently
pick_random_neighbor(full, Id, NumNodes, _Neighbors) ->
    case NumNodes of
        1 -> Id;
        _ ->
            R = rand:uniform(NumNodes - 1),
            if R >= Id -> R + 1; true -> R end
    end;
pick_random_neighbor("full", Id, NumNodes, Neighbors) ->
    pick_random_neighbor(full, Id, NumNodes, Neighbors);
pick_random_neighbor(_Topology, _Id, _NumNodes, Neighbors) ->
    case Neighbors of
        [] -> self();
        [Single] -> Single;
        _ ->
            Index = rand:uniform(length(Neighbors)),
            lists:nth(Index, Neighbors)
    end.
