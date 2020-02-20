%% Generate Training Data for Intonation Space
%ifolder = 'C:\Users\mFry2\Google Drive\My Research\InAMo (QP2)\Code\IDS_waves';
%[d,fs, rejUtt] = generate_training_data(ifolder);

%% Train Target Intonation Space
rFolder = 'C:\Users\mf\Google Drive\Research\QPs\InAMo (QP2)\Code\Processed IDS Data';
rFiles = getAllFiles(rFolder);
nSenAmpParam = 50;
nSenF0Param = 50;
nTotSenParam = nSenAmpParam + nSenF0Param;
trainData = zeros(7623, nTotSenParam);
tIdx = 1;
for ii = 1:size(rFiles, 1)
    cData = load(rFiles{ii});
    rFile = fields(cData);
    cData = cData.(rFile{1});
    for jj = 1:size(cData, 1)
        trainData(tIdx, :) = [cData{jj, 3}' cData{jj,4}'];
        tIdx = tIdx + 1;
    end
end

% Normalize Values
maxAmp = max(max(trainData(:, 1:nSenAmpParam)));
minAmp = min(min(trainData(:, 1:nSenAmpParam)));
maxF0 = max(max(trainData(:, nSenAmpParam+1:nTotSenParam)));
minF0 = min(min(trainData(:, nSenAmpParam+1:nTotSenParam)));

% Keep history of parameters
normParams.minAmp = minAmp; normParams.maxAmp = maxAmp;
normParams.minF0 = minF0; normParams.maxF0 = maxF0;
normParams.nTotParams = nTotSenParam;
normParams.nSensAmpParams = nSenAmpParam;

% Normalize data
trainData(:, 1:nSenAmpParam) = (trainData(:, 1:nSenAmpParam)-minAmp)/(maxAmp-minAmp);
trainData(:, nSenAmpParam+1:nTotSenParam) = (trainData(:, nSenAmpParam+1:nTotSenParam)-minF0)/(maxF0-minF0);

% Initialize & Train Target Intonation Space SOM
targetSOM = initializeSOM(10, 10, nTotSenParam);
nEpoch = 30; t = 1;
tic
trackTargetErrs = zeros(size(trainData,1), 4);
for jj = 1:size(trainData,1)
            [~, ~, ~, trackTargetErrs(jj, 1)] = getSOMBMUErr(targetSOM, trainData(jj,:));
end

for ii = 1:nEpoch
    if mod(ii, 10) == 0
        toc
        disp(['Epoch: ' num2str(ii) ' of ' num2str(nEpoch)]);
        for jj = 1:size(trainData,1)
            [~, ~, ~, trackTargetErrs(jj, ii/10 + 1)] = getSOMBMUErr(targetSOM, trainData(jj,:));
        end

    end
    [targetSOM, t] = trainSOM(targetSOM, trainData, t);
end



% Show BMU correspondence for an example
%[~, ~, BMUrow, BMUcol] = trainSOM(targetSOM, trainData(1,:), t);
%figure; subplot(121); plot(trainData(1, 1:50)); subplot(122); plot(trainData(1, 51:100));
%[sig, amp, f0] = visuSOMIntPhr(targetSOM, [BMUrow BMUcol], normParams);

%SMIM Parameters
motCust.chunkSize = 5; motCust.tolerance = 0.05;
motParamInfPts = 5;                     % Five intonational inflection points
nMusc = 7;                              % Seven larygneal muscles
nTotMotParam = nMusc * motParamInfPts;
ErrMean = mean(trackTargetErrs(:,end));
ErrStd = std(trackTargetErrs(:,end));
ErrThresh = ErrMean + ErrStd;
% Run multiple simulations in parallel
for qq = 1
    %% Initialize SMIM Learning Model
    motSOM = initializeSOM(10, 10, nTotMotParam);
    senSOM = initializeSOM(10, 10, nTotSenParam);
    hebbCon = zeros(100, 100);

    %% Begin SMIM Learning
    % Generate an utterance and convert it to intonation
    netHist = cell(24, 10); 
    
    keepMotActs = []; kMPIdx = 1; t = 1;
    keepSenActs = []; kSPIdx = 1; dur = 0.5;
    for jj = 1:25
        % Track Learning History
        disp(['Network Learning Block: ' num2str(jj)]);
        netHist{jj, 1} = (100*(jj-1))+1;
        %netHist{jj, 2} = correlateSOM(targetSOM, senSOM, 1);
        %netHist{jj, 3} = correlateSOM(targetSOM, senSOM, 2);
        netHist{jj, 4} = targetSOM;
        netHist{jj, 5} = motSOM;
        netHist{jj, 6} = senSOM;
        netHist{jj, 7} = hebbCon;
        currErrTarg = zeros(size(trainData,1), 1);
        for pp = 1:size(trainData,1)
            [~, ~, ~, currErrTarg(pp)] = getSOMBMUErr(senSOM, trainData(pp,:));
        end
        netHist{jj, 8} = currErrTarg;
        goodMotParam = 0;
        % Check all MotParams to see if they are desirable (output utterance
        % close to something in the target map)
        for kk = 1:10
            for ll = 1:10
                motX = kk; motY = ll;
                motActs = getSOMParam(motSOM, [motX motY]);
                [spontUtt, fs] = make_utterance(dur, motActs, ['tmp' num2str(qq)]);
                [s, intonS, f, amp, good] = convert_to_intonation(spontUtt, fs);
                %New command to get f0 via reaper via bash via command line
                iCmd = ['"bash -c "/home/mfry/github/reaper/REAPER/build/reaper -i /mnt/c/Users/Michael/Desktop/slow3.wav -f /mnt/c/Users/Michael/Desktop/bla3.f0 -a"'];
                system(iCmd);
                if good
                    f = (f-minF0)/(maxF0-minF0); amp = (amp-minAmp)/(maxAmp-minAmp);
                    senActs = [amp f'];
                    [~, BMUrow, BMUcol, Err] = getSOMBMUErr(targetSOM, senActs);
                    if Err < ErrThresh
                        keepSenActs(kSPIdx, :) = senActs; kSPIdx = kSPIdx + 1;
                        keepMotActs(kMPIdx, :) = motActs; kMPIdx = kMPIdx + 1;
                        goodMotParam = goodMotParam + 1;
                    end
                end
            end
        end
        netHist{jj,9} = goodMotParam;
        netHist{jj,10} = ErrThresh;
        % Self-Organizing Maps for desirable utterances
        [motSOM, t] = trainSOM(motSOM, keepMotActs, t);
        [senSOM, t] = trainSOM(senSOM, keepSenActs, t);
        
        % Update hebbian connections
        for kk = 1:size(keepMotActs,1)
            hebbCon = updateHebbCon(hebbCon, motSOM, senSOM, keepMotActs(kk,:), keepSenActs(kk,:));
        end
        keepMotActs = []; kMPIdx = 1;
        keepSenActs = []; kSPIdx = 1;
    end
    parsave_simple(['C:\Users\mFry2\Google Drive\My Research\InAMo (QP2)\Code\learningSimulations\ParalRun' num2str(qq)], netHist);
end %End par for
