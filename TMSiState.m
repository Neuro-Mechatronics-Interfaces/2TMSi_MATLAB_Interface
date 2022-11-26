classdef TMSiState < uint8
    %TMSISTATE  Enumeration class (uint8) for TMSiSAGA device state machine.
    %
    % Enumerated values:
    %   IDLE        (0)
    %   RUNNING     (1)
    %   RECORDING   (2)
    %   IMPEDANCE   (3)
    %   QUIT        (4)
    
    enumeration
        IDLE        (0)
        RUNNING     (1)
        RUN         (1)
        RECORDING   (2)
        REC         (2)
        IMPEDANCE   (3)
        IMP         (3)
        QUIT        (4)
    end
end
