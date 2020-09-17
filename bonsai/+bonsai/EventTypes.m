% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% Event type enumeration for the Bonsai toolbox

classdef EventTypes

    properties
        str
    end

    methods

        function e = EventTypes(s)
            e.str = s;
        end

        function tf = eq(event1, event2)
            if ~strcmp(class(event2), 'bonsai.EventTypes')
                tf = false;
            else
                tf = strcmp(event1.str, event2.str);
            end
         end

    end

    enumeration
        Registered      ('Registered')
        Idle            ('Idle')
        EpisodeStart    ('EpisodeStart')
        EpisodeStep     ('EpisodeStep')
        EpisodeFinish   ('EpisodeFinish')
        PlaybackStart   ('PlaybackStart')
        PlaybackStep    ('PlaybackStep')
        PlaybackFinish  ('PlaybackFinish')
        Unregister      ('Unregister')
    end

end
