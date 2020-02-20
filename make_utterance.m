function [synth_sig, sr] = make_utterance(duration, acts, oFile)
% duration - length of utterance
% artPoints - number of points for articulators
% muscles - list of muscles
% acts - flattened array of num(muscles) by artPoints
% oFile - filename for the praat and wav files
load('C:\Users\mf\Google Drive\Research\QPs\InAMo (QP2)\Code\PraatSynthTemplates\larynxMusc.mat');
artPoints = length(acts)/size(fields(muscles),1);
% Generate complete muscle activation object
muscleActs = genMuscleActs(duration, artPoints, muscles, acts);
% Initialize .praat script for the utterance
file_output = {'Create Speaker... jynx Female 2'; ...
              ['Create Artword... jynx ' num2str(duration)]; ...
               'select Artword jynx'};

pFile = ['C:\Users\mf\Google Drive\Research\QPs\InAMo (QP2)\Code\' oFile '.praat'];
sFile = ['C:\Users\mf\Google Drive\Research\QPs\InAMo (QP2)\Code\' oFile '.wav'];

muscles = fields(muscleActs); idx = 4;
for ii = 1:length(muscles)
    cAct = muscleActs.(muscles{ii});
    for jj = 1:size(muscleActs.(muscles{ii}))
        file_output{idx} = ['Set target... ' num2str(cAct(jj, 1)) ...
            ' ' num2str(cAct(jj, 2)) ' ' muscles{ii}];
        idx = idx + 1;
    end
end
file_output{idx} = 'select Speaker jynx';
file_output{idx+1} = 'plus Artword jynx';
file_output{idx+2} = 'To Sound... 22050 25 0 0 0 0 0 0 0 0 0';
file_output{idx+3} = 'select Sound jynx_jynx';
file_output{idx+4} = ['Save as WAV file... ' sFile];
cell_to_file(file_output, pFile);

iCmd = ['"C:\Program Files\Praat\Praat.exe" --run "' pFile '"'];
system(iCmd);
[synth_sig, sr] = audioread(sFile);
delete(pFile, sFile);
end

function muscleActs = genMuscleActs(duration, artPoints, muscles, acts)
    t = 0:duration/(artPoints-1):duration;
    muscleNames = fields(muscles);
    for ii = 1:length(muscleNames)
        cIdx = (ii-1)*artPoints + 1;
        muscles.(muscleNames{ii}) = [t' acts(cIdx:cIdx+(artPoints-1))'];
    end
    load('C:\Users\mf\Google Drive\Research\QPs\InAMo (QP2)\Code\PraatSynthTemplates\baseMuscles.mat');
    baseMuscNames = fields(baseMuscles);
    for jj = 1:length(baseMuscNames)
        if strcmp(baseMuscNames{jj}, 'Lungs')
            muscles.(baseMuscNames{jj}) = [[0;t(end)/5] baseMuscles.(baseMuscNames{jj})(:, 2)];
        else
            muscles.(baseMuscNames{jj}) = [[0;t(end)] baseMuscles.(baseMuscNames{jj})(:, 2)];
        end
    end
    muscleActs = muscles;
end

function cell_to_file(data, filename)
    fileID = fopen(filename, 'w');
    formatSpec = '%s\n';
    for r = 1:size(data, 1)
        fprintf(fileID, formatSpec, data{r, :});
    end
    fclose(fileID);
end