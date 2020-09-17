% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% Function to get datatypes and signal names from Bonsi block ports

function portdata = GetPortData(bonsaiblock)

    ph = get_param(bonsaiblock, 'PortHandles');
    actionport = ph.Outport(1);
    portdata.actionSchema = string(get_param(actionport, 'SignalNameFromLabel'));
    portdata.actionType = string(get_param(actionport, 'CompiledPortDataType'));
    
    % Fill the action port if there are no signal names
    if portdata.actionSchema == ""
        port_dimensions = prod(get_param(actionport, 'CompiledPortDimensions'));
        portdata.actionSchema = strings(1, port_dimensions);
        for ct = 1:port_dimensions
            portdata.actionSchema(ct) = sprintf("Signal %d", ct);
        end
    end
    
    % Handle the state ports
    stateport = ph.Inport(1);
    portdata.stateSchema = string(get_param(stateport, 'SignalNameFromLabel'));
    portdata.stateType = string(get_param(stateport, 'CompiledPortDataType'));
    
    % If the signal labels are empty see if there is a mux port coming in so we
    % can get the signal labels
    if portdata.stateSchema == ""
        ph = get_param(bonsaiblock, 'PortConnectivity');
        srcblock = ph(1).SrcBlock;
        if strcmp(get_param(srcblock, 'BlockType'), 'Mux')
            ph = get_param(srcblock, 'PortHandles');
            inports = ph.Inport;
            signals = string(zeros(0, 1));
            for ct = 1:numel(inports)
                l = get_param(inports(ct), 'Line');
                n = get_param(l, 'Name');
                if ~isempty(n)
                    signals(end + 1) = string(n);
                else
                    signals(end+ 1 ) = sprintf("Signal %d", ct);
                end
            end
        portdata.stateSchema = signals;
        else
            port_dimensions = prod(get_param(stateport, 'CompiledPortDimensions'));
            portdata.stateSchema = strings(1, port_dimensions);
            for ct = 1:port_dimensions
                portdata.stateSchema(ct) = sprintf("Signal %d", ct);
            end
        end
    end
end
