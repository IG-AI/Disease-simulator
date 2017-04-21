%% Includes %%

%% @type person(). The persons in the simulation.
-type person() :: {status(),position(),direction()}.
%% @type state(). The state of the simulation. 
-type state() :: [{pid(),person()}].
%% @type status(). The status of a persons health.
-type status() :: integer().
%% @type direction(). The direction a person is moving {X_change, Y_change}.
-type direction() :: {integer(), integer()}.
%% @type bounds(). The bounds of a map. {max X position, max Y position}
-type bounds() :: {integer(), integer()}.
%% @type position. coordinates for a position on the map.
-type position() :: {integer(), integer()}.

-include_lib("eunit/include/eunit.hrl").

