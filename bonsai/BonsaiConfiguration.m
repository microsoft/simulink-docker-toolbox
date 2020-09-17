% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% Configuration base class for the Bonsai toolbox

classdef BonsaiConfiguration < handle

    properties
        url char
        name char
        workspace char
        accessKey char
        context char
        stateSchema string
        actionSchema string
        configSchema string
        stateType char
        actionType char
        configType char
        bonsaiBlock char
        timeout
        outputCSV char
        verbose logical
	    predict logical
    	predictionUrl char
    end

    properties (Constant, Access = private)
        logger = bonsai.Logger('BonsaiConfiguration', false)
        identifier = 'bonsai:BonsaiConfiguration'
    end

    methods

        function obj = BonsaiConfiguration()
            obj.url = 'https://api.bons.ai';
            obj.name = '';
            obj.workspace = '';
            obj.accessKey = '';
            obj.context = '';
            obj.stateSchema = strings(0);
            obj.actionSchema = strings(0);
            obj.configSchema = strings(0);
            obj.stateType = 'double';
            obj.actionType = 'double';
            obj.configType = 'double';
            obj.bonsaiBlock = '';
            obj.timeout = 60;
            obj.outputCSV = '';
            obj.verbose = false;
            obj.predict = false;
	        obj.predictionUrl = 'http://localhost:5000/v1/prediction';
        end

        % set properties from the environment, if present

        function obj = set.url(obj, url)
            env_host = getenv('SIM_API_HOST');
            if isempty(env_host)
                obj.url = char(url);
            else
                obj.logger.log('Using SIM_API_HOST from the environment');
                obj.url = char(env_host);
            end
        end

        function obj = set.workspace(obj, w)
            env_workspace = getenv('SIM_WORKSPACE');
            if isempty(env_workspace)
                obj.workspace = char(w);
            else
                obj.logger.log('Using SIM_WORKSPACE from the environment');
                obj.workspace = char(env_workspace);
            end
        end

        function obj = set.accessKey(obj, accessKey)
            env_accessKey = getenv('SIM_ACCESS_KEY');
            if isempty(env_accessKey)
                obj.accessKey = char(accessKey);
            else
                obj.logger.log('Using SIM_ACCESS_KEY from the environment');
                obj.accessKey = char(env_accessKey);
            end
        end

        function obj = set.context(obj, context)
            env_context = getenv('SIM_CONTEXT');
            if isempty(env_context)
                obj.context = char(context);
            else
                obj.logger.log('Using SIM_CONTEXT from the environment');
                obj.context = char(env_context);
            end
        end

        % convert strings to char arrays as they are set

        function obj = set.name(obj, name)
            obj.name = char(name);
        end

        function obj = set.outputCSV(obj, csv)
            obj.outputCSV = char(csv);
        end

	function obj = set.predictionUrl(obj, predictionUrl)
            obj.predictionUrl = char(predictionUrl);
        end

        % helper functions

        function enabled = csvWriterEnabled(obj)
            enabled = ~strcmp(obj.outputCSV, '');
            if obj.inContainer()
                enabled = false;
            end
        end

        function n = numStates(obj)
            n = length(obj.stateSchema);
        end

        function n = numActions(obj)
            n = length(obj.actionSchema);
        end

        function n = numConfigs(obj)
            n = length(obj.configSchema);
        end

        function r = registrationJson(obj)

            function description = generateDescription(fields, numFields, fieldType)
                description = struct();
                if numFields > 0
                    typeCategory = 'Number';
                    if ~strcmp(fieldType, 'double')
                        error(obj.identifier, 'Invalid BonsaiConfiguration: schemas must be type "double".');
                    end
                    fieldObjects = cell(1, numFields);
                    for k = 1:numFields
                        fieldObject = struct('name', fields(k), 'type', struct('category', typeCategory));
                        fieldObjects(1, k) = {fieldObject};
                    end
                    description = struct( ...
                        'category', 'Struct', ...
                        'fields', {fieldObjects} ...
                    );
                end
            end

            stateObject = generateDescription(obj.stateSchema, obj.numStates, obj.stateType);
            actionObject = generateDescription(obj.actionSchema, obj.numActions, obj.actionType);
            configObject = generateDescription(obj.configSchema, obj.numConfigs, obj.configType);

            descriptionObject = struct( ...
                'state', stateObject, ...
                'action', actionObject, ...
                'config', configObject ...
            );

            registrationObject = struct( ...
                'capabilities', struct(), ...
                'name', obj.name, ...
                'timeout', obj.timeout, ...
                'description', descriptionObject, ...
                'simulatorContext', obj.context ...
            );

            r = jsonencode(registrationObject);
        end

        function validate(obj)

            function tf = hasDuplicates(schema)
                tf = true;
                if length(schema) == length(unique(schema))
                    tf = false;
                end
            end

            % error if any required values are missing
            if isempty(obj.url)
                error(obj.identifier, 'Invalid BonsaiConfiguration: url cannot be empty.');
            elseif isempty(obj.name)
                error(obj.identifier, 'Invalid BonsaiConfiguration: name cannot be empty.');
            elseif isempty(obj.workspace)
                error(obj.identifier, 'Invalid BonsaiConfiguration: workspace cannot be empty.');
            elseif isempty(obj.accessKey)
                error(obj.identifier, 'Invalid BonsaiConfiguration: accessKey cannot be empty.');
            end

            % if bonsaiBlock is not provided, require stateSchema and actionSchema
            if isempty(obj.bonsaiBlock)
                if isempty(obj.stateSchema) || isempty(obj.actionSchema)
                    error(obj.identifier, 'Invalid BonsaiConfiguration: stateSchema and actionSchema must be set if no bonsaiBlock is provided.');
                end
            end

            % make sure schemas contain no duplicates
            if hasDuplicates(obj.stateSchema)
                error(obj.identifier, 'Invalid BonsaiConfiguration: stateSchema contains duplicate values.');
            elseif hasDuplicates(obj.actionSchema)
                error(obj.identifier, 'Invalid BonsaiConfiguration: actionSchema contains duplicate values.');
            elseif ~isempty(obj.configSchema) && hasDuplicates(obj.configSchema)
                error(obj.identifier, 'Invalid BonsaiConfiguration: configSchema contains duplicate values.');
            end

            % timeout must be positive integer
            if ~isnumeric(obj.timeout) || ~isequal(length(obj.timeout), 1) || obj.timeout < 1
                error(obj.identifier, 'Invalid BonsaiConfiguration: timeout must be a positive integer.');
            end

            % only 'double' type is supported for schemas (for now)
            doubleType = 'double';
            if ~strcmp(obj.stateType, doubleType)
                error(obj.identifier, ['Invalid BonsaiConfiguration: invalid stateType ', ...
                    obj.stateType, ', only type "double" supported at this time.']);
            elseif ~strcmp(obj.actionType, doubleType)
                error(obj.identifier, ['Invalid BonsaiConfiguration: invalid actionType ', ...
                    obj.actionType, ', only type "double" supported at this time.']);
            elseif ~strcmp(obj.configType, doubleType)
                error(obj.identifier, ['Invalid BonsaiConfiguration: invalid configType ', ...
                    obj.configType, ', only type "double" supported at this time.']);
            end

            obj.logger.log('BonsaiConfiguration is valid.');
        end

    end

    methods (Access = private)

        function tf = inContainer(obj)
            % assume we are NOT in a container unless all Animatrix variables exist
            tf = false;
            if ~isempty(getenv('SIM_CONTEXT')) && ...
                ~isempty(getenv('SIM_API_HOST')) && ...
                ~isempty(getenv('SIM_WORKSPACE')) && ...
                ~isempty(getenv('SIM_ACCESS_KEY'))
                tf = true;
            end
        end

    end

end