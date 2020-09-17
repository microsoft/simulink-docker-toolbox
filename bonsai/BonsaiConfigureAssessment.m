% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% function to configure assessment of a Bonsai brain

function BonsaiConfigureAssessment(config, mdl, episodeStartCallback)

    % configure session
    session = bonsai.Session.getInstance();
    session.configure(config, mdl, episodeStartCallback, false);

    % print success
    logger = bonsai.Logger('BonsaiConfigureAssessment', config.verbose);
    logger.log('Configuration for assessment complete.');

end
