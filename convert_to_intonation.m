function [s, intonS, f, amp, eval] = convert_to_intonation(s, fs)
% Set up parametres
len = length(s);
lenTime = len/fs;
sOrig = s;
[coeffb,coeffa] = butter(6, [125/(fs/2) 1000/(fs/2)], 'bandpass');
s = filter(coeffb,coeffa,s);
    
t = 1/fs:1/fs:lenTime;
fac = NaN(len, 1);
%fcep = NaN(len, 1);
%fzc = NaN(len, 1);
frWin = round(75*fs/1000); frShift = round(5*fs/1000);
[fr, ~] = vec2frames(s, frWin, frShift, 'cols');
currIdx = 1;

for ii = 1:size(fr, 2)
    % Approximate F0
    currFr = fr(:,ii);
    
    % Estimate F0 with Autocorrelation
    ac = xcorr(currFr, currFr);
    ac = ac(floor(end/2):end);
    ac = sgolayfilt(sgolayfilt(ac, 1, 27), 1, 27);
    [pks, loc, p, w] = findpeaks(ac);
    if isempty(diff(loc))
         intonS = NaN; f = NaN; eval = false; amp = NaN;
        return
    else
        estF0 = fs/mode(diff(loc));
        estF0 = round(estF0);   
    end
    
    %{
    Estimate F0 with cepstrum
    dt = 1/fs;
    c = abs(fft(log(abs(currFr))));
    c = sgolayfilt(c, 1, 13);
    tt = 0:dt:length(currFr)*dt-dt;
    trng = tt(tt>=2e-3 & tt<=8e-3);
    crng = c(tt>=2e-3 & tt<=8e-3);
    [~,I] = max(crng);
    estF0cep = 1/trng(I);
    %}
    
    %{
    Estimate F0 with zero-crossing
    currFrNorm = currFr - mean(currFr);
    currFrLag = zeros(length(currFrNorm),1);
    currFrLag(1:length(currFr)-1) = currFrNorm(2:length(currFr));
    zc = length(find((currFrNorm>0 & currFrLag<0) | (currFrNorm<0 & currFrLag>0)));
    estF0zc = 0.5*fs*zc/length(currFr);
    %}
    
    % Add rms and F0 into intonation profile
    tempFac = repmat(estF0, length(currFr), 1);
    %tempFcep = repmat(estF0cep, length(currFr),1);
    %tempFzc = repmat(estF0zc, length(currFr), 1);
    currRange = currIdx:currIdx+length(currFr)-1;
    fac(currRange) = nanmean([fac(currRange); tempFac]);
    %fcep(currRange) = nanmean([fcep(currRange); tempFcep]);
    %fzc(currRange) = nanmean([fzc(currRange); tempFzc]);
    currIdx = currIdx+round(5*fs/1000);
end
try
    % Generate signal with specific F0
    smoothFact = min([99 round(length(fac)/2)]);
    if mod(smoothFact, 2) == 0
        smoothFact = smoothFact - 1;
    end
    fac = sgolayfilt(fac, 1, smoothFact);
    %fzc = sgolayfilt(fzc, 1, 99);
    %fcep = sgolayfilt(fcep, 1, 99);
    % Estimate F0 with SHRP
    [~,estF0shrp, ~,~] = shrp(s, fs, [100 500], 75, 5);
    fshrp = match_length(estF0shrp, fac);
    [f, eval] = combineF0(fac, fshrp, 0, 0);
    intonS = sin(2*pi*f.*t');
    intonS(isnan(intonS)) = [];

    % Filter out any artifactual pitches
    [b,a] = butter(6, (.75*nanmedian(f))/(fs/2), 'high');
    intonS = filter(b,a,intonS);
    [b,a] = butter(6, (1.25*nanmedian(f))/(fs/2), 'low');
    intonS = filter(b,a,intonS);

    % Match signals for RMS;
    ampOrig = rms(fr);
    frSyn = vec2frames(intonS, frWin, frShift, 'cols', @hamming);
    ampSyn = rms(frSyn);
    scaleAmp = repmat(ampOrig./ampSyn, size(frSyn,1), 1);
    frSyn = frSyn.*scaleAmp;
    intonS = frames2vec(frSyn, frShift, 'cols', @hamming, 'G&L');

    amp = interp(ampOrig, round(length(s)/length(ampOrig)));
    amp = resample(amp, length(s), length(amp));
    % outputs
    intonS = intonS/(max(abs(intonS)));
    s = sOrig/max(abs(sOrig));

    %Normalize F0 and amp lengths to 50 data points:
    f = f(1:round(length(f)/51):length(f));
    f = f(1:50);
    amp = amp(1:round(length(amp)/51):length(amp));
    amp = amp(1:50);
catch
    intonS = NaN; f = NaN; eval = false; amp = NaN;
    return 
end
end

function [F0, eval] = combineF0(fac, fshrp, plotBA, stopCheck)
    F0 = zeros(length(fac), 1);
    compareF0 = fac-fshrp;
    compatIdx = abs(compareF0) < 15;
    F0(compatIdx) = fac(compatIdx);
    if plotBA == 1
        plot(F0);
    end
    st = 0;
    for ii = 1:length(F0)-1
        if F0(ii) ~= 0 && F0(ii+1) == 0
            st = ii;
        elseif F0(ii) == 0 && F0(ii+1) ~= 0 && st ~=0;
            en = ii+1;
            idxFill = st+1:en-1;
            if F0(st) ~= F0(en)
                fillVal = F0(st):(F0(en)-F0(st))/(en-st):F0(en);
            else
                fillVal = repmat(F0(st), 1, en-st+1);
            end
            F0(idxFill) = fillVal(2:end-1);
        elseif F0(ii) == 0 && F0(ii+1) ~= 0 && st == 0;
            F0(1:ii) = repmat(F0(ii+1), ii, 1);
        elseif ii == length(F0)-1 && F0(ii-1) == 0
            F0(st+1:end) = repmat(F0(st), length(F0)-st, 1);
        end
    end
    if sum(compatIdx) < length(F0)/6
        if ~stopCheck
            [F0, eval] = combineF0(fac/nanmean(fac./fshrp), fshrp, plotBA, 1);
        else
            eval = false;
        end
    else
        eval = true;
    end
    if plotBA == 1
        clf;
        plot(F0);
        winSm = round(length(F0)/12); 
        if mod(winSm, 2) == 0
            winSm = winSm + 1;
        end
        F0 = sgolayfilt(F0, 1, winSm);
        hold
        plot(F0);
    end
end