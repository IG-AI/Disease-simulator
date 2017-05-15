-module(record).
-include("includes.hrl").
-export([start_record/3]).


%% @doc Starts the process identified by the atom 'record' messages sent to this process
%% instead of the Java-process will be saved to disk
%% @param Record controls behaviour of the function, and parameters sent to record
%% 
-spec start_record(Record :: atom(), Java_connection :: java_connection(), Map :: [non_neg_integer()]) -> no_return().
start_record(rec, _, Map) ->
    master ! ready_for_positions,
    register(record, spawn(fun() -> record(proper_time:time_to_string()++".record", start, e_master, Map) end));

start_record(play_and_rec, Java, Map) ->
    Java ! {set_up_for_requests},
    register(record, spawn(fun() -> record(proper_time:time_to_string()++".record", start, none, Map) end));

start_record(play, Java, _) ->  %bg|play
    Java ! {set_up_for_requests},
    register(record, spawn(fun() -> record() end));

start_record(_, _, _) -> 
    master ! ready_for_positions,
    register(record, spawn(fun() -> record() end)).

-spec record() -> no_return().
record() ->
    receive
        {simulation_done, _} ->
            master ! thanks_for_all_the_fish;
        _ ->
            record()
    end.

%% @doc record will listen for connections to 'record' and write them to it's supplied filepointer.
%%
%% @param Control Will contain either a filename to be appended to, or a pointer to an open file to write to
%% @param start|wait is used to decide if the process should open a file for writing
%% or wait for incoming messages with data to write
%% @param Reply control whom to reply to
%% 
-spec record(Control :: [non_neg_integer()]|pid(), start|simulation_done|wait, Reply :: boolean(), Map :: non_neg_integer()) -> no_return().
record(Filename, start, Reply, Map)->
    %öppna fil för skrivning
    case file:open("logs/"++Filename, [append]) of
        {ok, Pointer} ->
            case file:write(Pointer, io_lib:fwrite("~p~n", [Map])) of
                {error, Reason} ->
                    io:format("Could not open file: ~p ~n", [Reason]);
                _ ->
                    io:format("Recording simulation to: ~p ~n", [Filename]),
                    record(Pointer, wait, Reply)
            end;
        {error, Reason} ->
            io:format("Could not open file: ~p ~n", [Reason])
    end.

%% @doc record will listen for connections to 'record' and write them to it's supplied filepointer.
%%
%% @param Control Will contain either a filename to be appended to, or a pointer to an open file to write to
%% @param start|wait is used to decide if the process should open a file for writing
%% or wait for incoming messages with data to write
%% @param Reply control whom to reply to
%% 
-spec record(Control :: [non_neg_integer()]|pid(), start|simulation_done|wait, Reply :: boolean()) -> no_return().
record(Pointer, wait, Reply) ->
    receive
        {updated_positions, New_state} ->
            %io:fwrite(Pointer, "~w~n", [New_state]),
            case file:write(Pointer, io_lib:fwrite("~p~n",[New_state])) of %this is probably faster and can handle more data than io:fwrite()
                {error, Reason} ->
                    io:format("Could not write to file: ~p ~n", [Reason]);
                _ ->
                    case Reply of
                        e_master ->
                            master ! ready_for_positions ,
                            record(Pointer, wait, Reply);
                        none ->
                            record(Pointer, wait, Reply)
                    end
            end;
        {simulation_done, Time_data} ->
            io:fwrite(Pointer, "~p~n", [Time_data]),
            case file:close(Pointer) of
                {error, Reason} ->
                    io:format("Could not close file: ~p ~n", [Reason]);
                _ ->
                    master ! thanks_for_all_the_fish
            end
    end.
