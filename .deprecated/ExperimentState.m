classdef ExperimentState < uint32
    %EXPERIMENTSTATE  Enumeration class for recording using Ripple stimulation in combination with shitty TMSi recording interface.
    %
    %   Any Serial device will have UserData struct with two fields:
    %   * 'state' : One of these states
    %   * 'data'  : Initialized as [], can be some arbitrary vector or more
    %               elaborate data structure, basically "reserved"
    
    enumeration
        INITIALIZING (0)
        SELECTING_PARAMETERS (1)
        AWAITING_RESPONSE (2)
        RUNNING (3)
        AWAITING_COMPLETION (4)
        PAUSED (5)
        COMPLETE (6)
    end
end

