% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% Networking client for the Bonsai toolbox



classdef PredictionClient

    properties (Access = private)
        config BonsaiConfiguration
        logger bonsai.Logger
    end

    methods

        function obj = PredictionClient(config)
            obj.config = config;
            obj.logger = bonsai.Logger('PredictionClient', config.verbose);
           
        end

        function r = makeRequest(obj, data, method, endpoint)

            urlString = obj.config.predictionUrl;
            requestUrl = matlab.net.URI(urlString);

            {
            options = weboptions('CharacterEncoding', 'UTF-8', ...
                'ContentType', 'json', ...
                'MediaType', 'application/json', ...
                'RequestMethod', method, ...
                'Timeout', 90);
            }

            obj.logger.verboseLog(char(strcat("Sending API ", method, " to ", urlString, ":")));
            obj.logger.verboseLog(data);

            r = webwrite(requestUrl, data, options);
          
            obj.logger.verboseLog('Response:');
            obj.logger.verboseLog(r);
            
        end

        function r = attemptRequest(obj, data, method)
            attempt = 0;
            maxAttempts = 50;
            success = false;
            while ~success && attempt < maxAttempts
                try
                    r = obj.makeRequest(data, method);
                    success = true;
                catch e
                    statusTimeout = 'MATLAB:webservices:Timeout';
                    status404 = 'MATLAB:webservices:HTTP404StatusCodeError';
                    status502 = 'MATLAB:webservices:HTTP502StatusCodeError';
                    status503 = 'MATLAB:webservices:HTTP503StatusCodeError';
                    status504 = 'MATLAB:webservices:HTTP504StatusCodeError';

                    if (strcmp(e.identifier, status404))
                        msg = ['Bonsai API "', method, ...
                            '" returned status code 404:\n', e.message];
                        throw(MException('Bonsai:Exception', msg));
                    elseif (strcmp(e.identifier, statusTimeout))
                        msg = ['Bonsai API took too long to respond:\n', e.message];
                        throw(MException('Bonsai:Exception', msg));
                    elseif (strcmp(e.identifier, status502) || ...
                            strcmp(e.identifier, status503) || ...
                            strcmp(e.identifier, status504))
                        obj.logger.log('Request received a 502/503/504 response, retrying...');
                        obj.logger.log(e);
                    else
                        obj.logger.log('Request generated un-handled error:');
                        obj.logger.log(e);
                        rethrow(e);
                    end
                    attempt = attempt + 1;
                    pause(1);
                end
            end

            if attempt >= maxAttempts
                error(['Request failed after ', num2str(maxAttempts), ' retries.']);
            end
        end


        function r = getNextEvent(obj, data)
            r = obj.attemptRequest(data, 'post');
        end

    end
end
