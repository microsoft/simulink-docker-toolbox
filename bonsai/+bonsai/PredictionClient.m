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

            %{
            options = weboptions('CharacterEncoding', 'UTF-8', ...
                'ContentType', 'json', ...
                'MediaType', 'application/json', ...
                'RequestMethod', method, ...
                'Timeout', 90);
            %}

            obj.logger.verboseLog(char(strcat("Sending API ", method, " to ", urlString, ":")));
            obj.logger.verboseLog(data);

            %r = webwrite(requestUrl, data, options);
          
            %{
            %%%%% using send -- doesnt work
            options = matlab.net.http.HTTPOptions('Authenticate',false,'VerifyServerName',false, 'UseProxy',false,'MaxRedirects',0);
            provider = matlab.net.http.io.JSONProvider(data);
            request = matlab.net.http.RequestMessage(matlab.net.http.RequestLine('GET'), [], provider);
            [request,url] = complete(request,requestUrl,options);
            
            % this works if we just return this
            %r = jsondecode('{"Kp":0.0019052563002333046,"Ki":0.06116210296750069}');
            
            disp('sending');
            
            [r,completedrequest,history] = send(request, url, options);
            
            completedrequest
            
            history
            
            %jsonencode(r.StatusCode)
            jsonencode(r.Header)
            jsonencode(r.Body)
            %}
            
            %{
                %%% using TCPIP - does not get a proper response
            %jdata = jsonencode(data);
            
            jdata = '{"Ki":0.061162102967500687,"Kip":0.061162102967500687,"Kp":0.0019052563002333045,"Kpp":0.0019052563002333045,"err_prev":39.60162911853331,"error":40.632192178592732,"iteration_count":5,"speed_ref":2000,"tnm":0.20059371070254789}';
           
            get = 'GET /v1/prediction HTTP/1.1';
            host = 'Host: localhost:5000 ';
            accept = 'accept: application/json';
            contentType = 'Content-Type: application/json';
            contentLen = strcat('Content-Length: ',num2str(strlength(jdata)));
            body = jdata;
            
            message = [get newline host newline accept newline contentType newline contentLen newline body];
            
            disp(message);
            
            t = tcpip('localhost',5000);
            t.Timeout = 5;
            t.Terminator = '*';
            fopen(t);
            t.Status
            
            pause(2);
            
            fprintf(t, message);
            
            r = fscanf(t);
            
            fclose(t);
            %}
            
            cmd = strcat('curl -s -X GET "', urlString,'" -H "accept: application/json" -H "Content-Type: application/json" -d ',jsonencode(data));
            
            [status,cmdout] = system(cmd);
            
            r = jsondecode(cmdout); %(start:strlength(cmdout)-start)
            
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
            r = obj.attemptRequest(data, 'get');
        end

    end
end
