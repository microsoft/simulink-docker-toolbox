% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% function to configure assessment of a Bonsai brain

function BonsaiConfigurePrediction(config, mdl, episodeStartCallback)

    % configure session
    session = bonsai.Session.getInstance();
    session.configure(config, mdl, episodeStartCallback, false);

    % print success
    logger = bonsai.Logger('BonsaiConfigurePrediction', config.verbose);
    logger.log('Configuration for prediction complete.');

end
