%% Plot Signal & its pitch/amplitude modulation
rFolder = 'C:\Users\Michael\Google Drive\Research\InAMo (QP2)\Code\Processed IDS Data';
rFiles = getAllFiles(rFolder);
cData = load(rFiles{1});
rFile = fields(cData);
cData = cData.(rFile{1});
fs = 22050;
figure
subplot(2,2, 1:2)
tT = length(cData{1,1}(1.4e3:end))/fs;
t = 0:tT/length(cData{1,1}(1.4e3:end)):tT;
plot(t(1:10:end-1), cData{1,1}(1.4e3:10:end));
xlim([0, tT]);
set(gca, 'fontsize', 10);
xlabel('Time (s)', 'fontsize', 12);
title('Speech Signal', 'fontsize', 14);

subplot(223);
plot(t(round(1:(length(t)-1)/50:end-1)), cData{1,4});
xlim([0, tT]);
set(gca, 'fontsize', 10);
xlabel('Time (s)', 'fontsize', 12);
ylabel('F0 (Hz)', 'fontsize', 12);
subplot(224);
plot(t(round(1:(length(t)-1)/50:end-1)), cData{1,3}/max(cData{1,3}))
xlim([0, tT]);
set(gca, 'fontsize', 10);
xlabel('Time (s)', 'fontsize', 12);
ylabel('Normalized Power', 'fontsize', 12);
set(gca, 'yaxislocation', 'right');

fig = gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 10 4];
fig.PaperOrientation = 'landscape';
fig.PaperPositionMode = 'manual';
fig.PaperSize = [10 4];

saveas(fig, 'C:\Users\Michael\Google Drive\Research\InAMo (QP2)\Code\zFig2_intProcess.pdf');

%% Loop over all simulations
for ii = 5:24
    load(['C:\Users\Michael\Google Drive\Research\InAMo (QP2)\Code\learningSimulations\ParalRun' num2str(ii) '.mat']);
    corrHist(ii-4, :) = [netHist{:,3}];
    learnTrial(ii-4, :) = [netHist{:,1}];
    goodMotParam(ii-4,:) = [netHist{:, 9}];
    beforeLearn(ii-4,:) = netHist{1, 8};
    afterLearn(ii-4,:) = netHist{end, 8};
end


%% Plot Topographical Correlation
figure;
corrHistMean = mean(corrHist);
learnTrialMean = mean(learnTrial);
plot(learnTrialMean/100, corrHistMean, 'linewidth', 0.25);
a = gca;
a.XLim = [1 learnTrialMean(end)/100];
set(a, 'fontsize', 13);
xlabel('Learning Block', 'fontsize', 16)
ylabel('Topographic Correlation', 'fontsize', 16);

fig = gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 5 3];
fig.PaperOrientation = 'landscape';
fig.PaperSize = [5 3];
fig.PaperPositionMode = 'Manual';

saveas(fig, 'C:\Users\Michael\Google Drive\Research\InAMo (QP2)\Code\zFig5_topCorr.pdf');

%% Plot number of good motor parameters
figure;
goodMotParamMean = mean(goodMotParam);
plot(learnTrialMean/100, goodMotParamMean, 'linewidth', 0.25);
a = gca;
a.XLim = [1 learnTrialMean(end)/100];
set(a, 'fontsize', 13);
xlabel('Learning Block', 'fontsize', 16);
ylabel('Number of Motor Neurons', 'fontsize', 16);

fig = gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 5 3];
fig.PaperOrientation = 'landscape';
fig.PaperSize = [5 3];
fig.PaperPositionMode = 'Manual';

saveas(fig, 'C:\Users\Michael\Google Drive\Research\InAMo (QP2)\Code\zFig6_nMotParam.pdf');

%% Compare error before and after training
figure;
beforeLearnMean = mean(sort(beforeLearn, 2));
afterLearnMean = mean(sort(afterLearn, 2));
histogram(beforeLearnMean, 'binwidth', 0.1);
hold
histogram(afterLearnMean, 'binwidth', 0.1);
legend('Before learning', 'After learning', 'Location', 'northwest');
legend('boxoff');
set(gca, 'fontsize', 14);
xlabel('Distance to BMU', 'fontsize', 18);
ylabel('# of training utterances', 'fontsize', 18)

fig = gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 6 3];
fig.PaperOrientation = 'landscape';
fig.PaperSize = [6 3];
fig.PaperPositionMode = 'Manual';

saveas(fig, 'C:\Users\Michael\Google Drive\Research\InAMo (QP2)\Code\zFig7_histErrs.pdf');

%% Single Comparison of Sensory Parameters
figure;
load(['C:\Users\Michael\Google Drive\Research\InAMo (QP2)\Code\learningSimulations\ParalRun' num2str(12) '.mat']);
sensVec = [cData{1,3}' cData{1,4}'];
sampRun = load('tmpRun.mat');
sensVec(:, 1:sampRun.nSenAmpParam) = (sensVec(:, 1:sampRun.nSenAmpParam)-sampRun.minAmp)/(sampRun.maxAmp-sampRun.minAmp);
sensVec(:, sampRun.nSenAmpParam+1:sampRun.nTotSenParam) = (sensVec(:, sampRun.nSenAmpParam+1:sampRun.nTotSenParam)-sampRun.minF0)/(sampRun.maxF0-sampRun.minF0);
[~, BMUrowPre, BMUcolPre, ~] = getSOMBMUErr(netHist{1,6}, sensVec);
preBMUVec = getSOMParam(netHist{1,6}, [BMUrowPre BMUcolPre]);
[~, BMUrowPost, BMUcolPost, ~] = getSOMBMUErr(netHist{end,6}, sensVec);
postBMUVec = getSOMParam(netHist{end,6}, [BMUrowPost BMUcolPost]);
subplot(121)
plot(sensVec, '--', 'linewidth', 2); hold;
plot(preBMUVec, 'linewidth', 0.5);
ylim([0 1.2]);
legend('Training utterance', 'SMIMGL BMU', 'location', 'northwest');
legend('boxoff');
set(gca, 'fontsize', 12);
xlabel('Sensory parameter index', 'fontsize', 18);
ylabel('Normalized amplitude/F0', 'fontsize', 20);

title('BMU before learning', 'fontsize', 24);
subplot(122)
plot(sensVec, '--', 'linewidth', 0.5); hold;
plot(postBMUVec, 'linewidth', 0.5);
ylim([0 1.2]);
legend('Training utterance', 'SMIMGL BMU', 'location', 'northeast');
legend('boxoff');
set(gca, 'fontsize', 12);
xlabel('Sensory parameter index', 'fontsize', 18);
%ylabel('Normalized amplitude/F0', 'fontsize', 20);
title('BMU after learning', 'fontsize', 24);


fig = gcf;
fig.PaperUnits = 'inches';
fig.PaperPosition = [0 0 12 4];
fig.PaperOrientation = 'landscape';
fig.PaperSize = [12 4];
fig.PaperPositionMode = 'Manual';

saveas(fig, 'C:\Users\Michael\Google Drive\Research\InAMo (QP2)\Code\zFig8_exempBMU.pdf');