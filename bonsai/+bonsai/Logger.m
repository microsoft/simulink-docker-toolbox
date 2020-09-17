% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% Logger class for the Bonsai toolbox

classdef Logger

    properties (Access = private)
        domain = ''
        verbose = false
    end

    methods

        function obj = Logger(domain, verbose)
            obj.domain = domain;
            obj.verbose = verbose;
        end

        function log(obj, s)
            obj.printLog(obj.domain, s);
        end

        function verboseLog(obj, s)
            if obj.verbose
                verboseDomain = [obj.domain, ':verbose'];
                obj.printLog(verboseDomain, s);
            end
        end

    end

    methods (Access = private)

        function printLog(obj, domain, s)
            timeStamp = char(datetime('now', 'TimeZone', 'UTC', ...
                                        'Format', 'yyyy-MM-dd:hh:mm:ss'));
            timeAndDomain = ['[', timeStamp, 'UTC ', domain, ']'];
            try
                if contains(s, '\')
                    fprintf(1, [timeAndDomain, newline]);
                    disp(s);
                else
                    fprintf(1, [timeAndDomain, ' ', s, newline]);
                end
            catch
                fprintf(1, [timeAndDomain, newline]);
                disp(s);
            end
        end

    end

end
