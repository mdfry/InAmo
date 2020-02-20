function [data, fs, rejectedUtt] = generate_training_data(ifolder)  
    % Load Transcript Files
    filelist = getAllFiles(ifolder);
    transcripts = filelist(~cellfun(@isempty, strfind(filelist, '.cha')));
    L = size(transcripts, 1); data = cell(L, 1); intPhrIdx = 1;
    for ii = 1:L
        disp(['On utterance ' num2str(ii) ' of ' num2str(L)]);
        % Process Transcript for Mother IDS speech boundaries
        curr_trans = textread(transcripts{ii}, '%s', 'whitespace', '\n');
        boundaries = get_utterance_boundaries(curr_trans);
        
        % Get Corresponding Audio File
        media_idx = ~cellfun(@isempty, strfind(curr_trans, '@Media'));
        curr_wav = curr_trans{media_idx}; curr_wav = [curr_wav(9:end-7) '.wav'];
        [fp, ~, ~] = fileparts(transcripts{ii});
        curr_wav = [fp '\' curr_wav];
        [x, fs] = audioread(curr_wav);
        
        % Splice audio file into individual utterances
        curr_data = cell(size(boundaries, 1)*2, 4); rejectedUtt = 0;
        for jj = 1:size(boundaries,1)
            c = 22.05;
            curr_sig = x(round(c*boundaries(jj, 1)):round(c*boundaries(jj,2)));
            try
                curr_sig_intPhr = separate_intonational_phrases(curr_sig, fs);
                for kk = 1:size(curr_sig_intPhr, 2); 
                        [s, intS, currF0, currAmp, goodness] = convert_to_intonation(curr_sig_intPhr{kk}, fs);
                        if ~goodness
                            rejectedUtt = rejectedUtt + 1;
                            continue
                        end
                        curr_data{intPhrIdx, 1} = s;
                        curr_data{intPhrIdx, 2} = intS;
                        curr_data{intPhrIdx, 3} = currAmp';
                        curr_data{intPhrIdx, 4} = currF0;
                        intPhrIdx = intPhrIdx + 1;
                end
            catch
                rejectedUtt = rejectedUtt + 1;
                disp('Sample not processed')
            end
            
        end
        curr_data(cellfun(@isempty, curr_data(:,1)), :) = [];
        eval(['TrainingSet' num2str(ii) ' = curr_data']);
        save(['C:\Users\mFry2\Google Drive\My Research\InAMo (QP2)\Code\Processed IDS Data2\TrainingSet' num2str(ii)], ['TrainingSet' num2str(ii)]);
        eval(['clear TrainingSet' num2str(ii)]);
    end
end

function boundaries = get_utterance_boundaries(trans)
    keep_idx = strfind(trans, '*MOT');
    keep_idx = ~cellfun(@isempty, keep_idx);
    mot_utter = trans(keep_idx);
    boundaries = zeros(size(mot_utter, 1), 2);
    for ii = 1:size(boundaries,1)
        idx = strfind(mot_utter{ii, 1}, '');
        if isempty(idx)
            continue
        else
            sample_idx = mot_utter{ii,1}(idx(1)+1:idx(2)-1);
            sample_idx = strsplit(sample_idx, '_');
            sample_idx = str2double(sample_idx);
            boundaries(ii, 1) = sample_idx(1);
            boundaries(ii, 2) = sample_idx(2);
        end
    end
    boundaries(boundaries(:,1)==0, :) = [];
end
