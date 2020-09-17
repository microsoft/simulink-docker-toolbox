% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% Generic helper functions for the Bonsai toolbox

classdef Utilities

   methods(Static)

        function orderedValues = getStructValuesInOrder(structInput, schemaInput)
            % Given an unordered dictionary (structInput) and an ordered array
            % of keys (schemaInput), return an ordered list of map values.

            % make sure struct is a struct
            if ~strcmp(class(structInput), 'struct')
                error('First argument must be of type struct.');
            end

            % ensure inputs are non-empty
            fields = fieldnames(structInput);
            if isempty(fields)
                error('Struct argument cannot be empty');
            elseif isempty(schemaInput)
                error('Schema argument cannot be empty');
            end

            % make sure input sizes match
            numFields = numel(fields);
            schemaLength = numel(schemaInput);
            if schemaLength ~= numFields
                error('Invalid inputs: struct and schema inputs have differing sizes');
            end

            % iterate over schema, writing to output var            
            orderedValues = zeros(1, schemaLength);
            for k=1:schemaLength
                orderedValues(k) = structInput.(schemaInput{k});
            end
        end

    end

end