% Copyright (c) Microsoft Corporation.
% Licensed under the MIT License.

% Model run loop for training a Bonsai brain

function BonsaiRunTraining(config, mdl, episodeStartCallback)
    logger = bonsai.Logger('BonsaiRunTraining', config.verbose);

    % configure and start session
    session = bonsai.Session.getInstance();
    session.configure(config, mdl, episodeStartCallback, true);
    session.startNewSession();

    % loop over training
    runException = [];
    try
        keepGoing = true;
        while keepGoing
            keepGoing = session.startNewEpisode();
        end
    catch runException
        % exception still gets checked below
    end

    % terminate session no matter what
    try
        session.terminateSession();
    catch terminateException
        % only raise there were no earlier exceptions
        if isempty(runException)
            rethrow(terminateException);
        end
    end

    % rethrow runExcpetion if not a user interrupt
    userTerminatedIdentifier = 'MATLAB:webservices:OperationTerminatedByUser';
    if ~isempty(runException)
        causeMessage = '';
        if ~isempty(runException.cause)
            causeMessage = runException.cause{1}.message;
        end
        if strcmp(runException.identifier, userTerminatedIdentifier) || ...
            contains(causeMessage, 'terminated by user') || ...
            contains(causeMessage, 'Program interruption (Ctrl-C) has been detected')
            logger.log('Session terminated by user.');
        else
            rethrow(runException);
        end
    end
end
