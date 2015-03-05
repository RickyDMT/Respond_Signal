function Respond_Signal_Training(varargin)
% Developed by ELK based on Schonberg et al., 2014
% Contact: elk@uoregon.edu
% Download latest version at: github.com/RickyDMT/Respond_Signal_Training

%Needs rated pics added.


global KEY COLORS w wRect XCENTER YCENTER PICS STIM RespST trial pahandle

prompt={'SUBJECT ID' 'Condition (1 or 2)' 'Session (1, 2, or 3)' 'Practice (1 or 0)'};
defAns={'4444' '1' '1' '1'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});
prac = str2double(answer{4});

file_check = sprintf('RespST_%d_%d.mat',ID,SESS);

%Make sure input data makes sense.
% try
%     if SESS > 1;
%         %Find subject data & make sure same condition.
%         
%     end
% catch
%     error('Subject ID & Condition code do not match.');
% end

%Make sure not over-writing file.
if exist(file_check,'file') == 2;
    error('File already exists. Please double-check and/or re-enter participant data.');
end


rng(ID); %Seed random number generator with subject ID
d = clock;

KEY = struct;
KEY.rt = KbName('SPACE');


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
% COLORS.GO = COLORS.BLUE';        %color of go rectangle
% COLORS.NO = [192 192 192]';     %color of no rectangle


STIM = struct;
STIM.blocks = 8;
STIM.trials = 44;
STIM.totes = STIM.blocks*STIM.trials;
STIM.go_trials = 160;
STIM.no_trials = 160;
STIM.neut_trials = 32;
STIM.trialdur = 1.5;
STIM.tone_delay = [.2,.3,.4];

%% Find and load pics
[imgdir,~,~] = fileparts(which('MasterPics_PlaceHolder.m'));
 picratefolder = fullfile(imgdir,'Saved_Pic_Ratings');  %This is name of folder at ORI

randopics = 0;

if COND == 1;  
    try
        cd(picratefolder)
    catch
        error('Could not find and/or open the folder that contains the ratings file.');
    end
    
    filen = sprintf('PicRatings_CC_%d-1.mat',ID);    %This only looks for ratings from initial session.
    try
        p = open(filen);
    catch
        warning('Could not find and/or open the rating file.');
        commandwindow;
        randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
        if randopics == 1
            p = struct;
            p.PicRating.go = dir('Healthy*');
            p.PicRating.no = dir('Unhealthy*');
            %XXX: ADD RANDOMIZATION SO THAT SAME 80 IMAGES AREN'T CHOSEN
            %EVERYTIME
        else
            error('Task cannot proceed without images. Contact Erik (elk@uoregon.edu) if you have continued problems.')
        end
        
    end
end
    
    cd(imgdir);
    
PICS =struct;
if COND == 1;                   %Condtion = 1 is food. 
    if randopics ==1;
        %randomly select 60 pictures.
        PICS.in.go = struct('name',{p.PicRating.H(randperm(60)).name}');
        PICS.in.no = struct('name',{p.PicRating.U(randperm(60)).name}');
        PICS.in.neut = dir('Water*');
    else

    %Choose the pre-selected random 60 from top 80 most appetizing pics)
    PICS.in.go = struct('name',{p.PicRating.H([p.PicRating.H.chosen]==1).name}');
    PICS.in.no = struct('name',{p.PicRating.U([p.PicRating.U.chosen]==1).name}');
    PICS.in.neut = dir('Water*');
    end
    
elseif COND == 2;               %Condition = 2 is not food (birds/flowers)
    PICS.in.go = dir('Bird*');
    PICS.in.no = dir('Flowers*');
    PICS.in.neut = dir('Mam*');
end

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.go) || isempty(PICS.in.no) || isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Set up trials and other stimulus parameters
RespST = struct;

trial_types = [ones(STIM.go_trials,1); repmat(2,STIM.no_trials,1); repmat(3,STIM.neut_trials,1)];  %1 = go; 2 = no; 3 = neutral/variable
gonogo = [ones(STIM.go_trials,1); zeros(STIM.no_trials,1)];                         %1 = go; 0 = nogo;
gonogoh20 = BalanceTrials(STIM.neut_trials,1,[0 1]);     %For neutral, go & no go are randomized
gonogo = [gonogo; gonogoh20];

%Make long list of #s to represent each pic
% piclist = [repmat([1:(STIM.go_trials/2)],1,2) repmat([1:(STIM.no_trials/2)],1,2)]';
% piclist = [repmat([1:(STIM.go_trials/2)],1,2) repmat([1:(STIM.no_trials/2)],1,2)]';
% piclist = [1:60; 1:60; randperm(60,rem(STIM.go_trials,60))'];

% if length(PICS.in.neut) >= STIM.neut_trials
%     piclist = [piclist; randperm(length(PICS.in.neut),STIM.neut_trials)'];
% else
%     diff = STIM.neut_trials - length(PICS.in.neut);
%     piclist = [piclist; randperm(length(PICS.in.neut))'; randperm(length(PICS.in.neut),diff)'];
% end

piclist = NaN(length(gonogo),1);

trial_types = [trial_types gonogo piclist]; %jitter];
shuffled = trial_types(randperm(size(trial_types,1)),:);

shuffled((shuffled(:,1)==1),3) = [randperm(60)'; randperm(60)'; randperm(60,rem(STIM.go_trials,60))'];
shuffled((shuffled(:,1)==2),3) = [randperm(60)'; randperm(60)'; randperm(60,rem(STIM.no_trials,60))'];
shuffled((shuffled(:,1)==3),3) = [randperm(20)'; randperm(20,rem(STIM.neut_trials,20))'];


delay = BalanceTrials(STIM.totes,1,STIM.tone_delay);
delay = delay(1:length(trial_types));   %Resample for length of total trials in case Balance Trials mucks it up

% trial_types = [trial_types gonogo piclist delay];
% 
% shuffled = trial_types(randperm(size(trial_types,1)),:);
shuffled = [shuffled delay];

for g = 1:STIM.blocks;
    row = ((g-1)*STIM.trials)+1;
    rend = row+STIM.trials - 1;
    RespST.var.trial_type(1:STIM.trials,g) = shuffled(row:rend,1);
    RespST.var.picnum(1:STIM.trials,g) = shuffled(row:rend,3);
    RespST.var.GoNoGo(1:STIM.trials,g) = shuffled(row:rend,2);
    RespST.var.delay(1:STIM.trials,g) = shuffled(row:rend,4);
end

    RespST.data.rt = NaN(STIM.trials, STIM.blocks);
    RespST.data.correct = NaN(STIM.trials, STIM.blocks)-999;
    RespST.data.avg_rt = NaN(STIM.blocks,1);
    RespST.data.picname = cell(STIM.trials,STIM.blocks);
    RespST.data.info.ID = ID;
    RespST.data.info.cond = COND;               %Condtion 1 = Food; Condition 2 = animals
    RespST.data.info.session = SESS;
    RespST.data.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    
commandwindow;

%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1);

screenNumber= max(Screen('Screens'));

if DEBUG==1;
    %create a rect for the screen
    winRect=[0 0 640 480];
    %establish the center points
    XCENTER=320;
    YCENTER=240;
else
    %change screen resolution
%    Screen('Resolution',0,1024,768,[],32); %This throws error on Macbook Air. Test again on PCs?
    
    %this gives the x and y dimensions of our screen, in pixels.
    [swidth, sheight] = Screen('WindowSize', screenNumber);
    XCENTER=fix(swidth/2);
    YCENTER=fix(sheight/2);
    %when you leave winRect blank, it just fills the whole screen
    winRect=[];
end

%open a window on that monitor. 32 refers to 32 bit color depth (millions of
%colors), winRect will either be a 1024x768 box, or the whole screen. The
%function returns a window "w", and a rect that represents the whole
%screen. 
[w, wRect]=Screen('OpenWindow', screenNumber, 0,winRect,32,2);


%% Sound stuff.
wave=sin(1:0.25:1000);
freq=22254;  % change this to change freq of tone
nrchannels = size(wave,1);
% Default to auto-selected default output device:
deviceid = -1;
% Request latency mode 2, which used to be the best one in our measurement:
reqlatencyclass = 2; % class 2 empirically the best, 3 & 4 == 2
% Initialize driver, request low-latency preinit:
InitializePsychSound(1);
% Open audio device for low-latency output:
pahandle = PsychPortAudio('Open', deviceid, [], reqlatencyclass, freq, nrchannels);

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,25);

KbName('UnifyKeyNames');

%% Set frame size;
STIM.imgrect = [XCENTER-300; YCENTER-300; XCENTER+300; YCENTER+300];



%% Initial screen
DrawFormattedText(w,'The respond signal task is about to begin.\nPress any key to continue.','center','center',COLORS.WHITE,[],[],[],1.5);
Screen('Flip',w);
KbWait();
Screen('Flip',w);
WaitSecs(1);

%% Instructions
DrawFormattedText(w,'You will see pictures on the screen. Some of the pictures will be followed by a tone (a beep).\n\nPlease the press the space bar as quickly as you can\nBUT only if you hear a beep after the image.\n\nDo not press if you do not hear a beep.\n\n\nPress any key to continue.','center','center',COLORS.WHITE,60,[],[],1.5);
Screen('Flip',w);
KbWait();

%% Practice

if prac == 1;

    practpic = imread(getfield(PICS,'in','neut',{1},'name'));
    practpic = Screen('MakeTexture',w,practpic);
    practpic2 = imread(getfield(PICS,'in','neut',{2},'name'));
    practpic2 = Screen('MakeTexture',w,practpic2);
    PsychPortAudio('FillBuffer', pahandle, wave);
    
    DrawFormattedText(w,' First, let''s practice.\n\nPress any key to continue.','center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait([],2);
    
    %GO PRACTICE
    DrawFormattedText(w,'In this trial, you will hear a beep. Press the space bar as quickly as you can AFTER you hear the beep.','center',YCENTER,COLORS.WHITE,60);
    Screen('Flip',w);
    KbWait([],2);
    
    prac_corr = 0;
    while prac_corr == 0
        Screen('DrawTexture',w,practpic,[],STIM.imgrect);
        prac_start = Screen('Flip',w);
        WaitSecs(.300);
        PsychPortAudio('Start', pahandle, 1);
        
        telap_prac = 0;
        while telap_prac < 1
            telap_prac = GetSecs() - prac_start;
            
            [pDown, ~, pCode] = KbCheck(); %waits for space bar to be pressed
            if pDown == 1 && find(pCode) == KEY.rt
                Screen('DrawTexture',w,practpic,[],STIM.imgrect);
                DrawFormattedText(w,'Good! Just remember to press it as quickly as you can after the beep!','center',YCENTER+330,COLORS.GREEN,60);
                Screen('Flip',w);
                prac_corr = 1;
                break
            elseif telap_prac > 1
                Screen('DrawTexture',w,practpic,[],STIM.imgrect);
                DrawFormattedText(w,'X\n\nPlease respond more quickly!\n\nPress the space bar as quickly after the beep as possible!\n Let''s try that again...','center',YCENTER,COLORS.RED,60);
                Screen('Flip',w);
                WaitSecs(3);
                Screen('Flip',w);
                WaitSecs(.5);
            end
        end
    end
    WaitSecs(5);
    
    Screen('Flip',w);
    WaitSecs(2);
    
    %NO GO PRACTICE
    DrawFormattedText(w,'Now let''s see one without a beep.','center','center',COLORS.WHITE);
    Screen('Flip',w);
    WaitSecs(3);
    
    Screen('Flip',w);
    WaitSecs(.5);
    
    prac_corr2 = 0;
    while prac_corr2 == 0;
        
        Screen('DrawTexture',w,practpic2,[],STIM.imgrect);
        prac_start = Screen('Flip',w);
        telap_prac = 0;
        while telap_prac < 1.5;
            telap_prac = GetSecs() - prac_start;
            
            [Down_pre, ~, Code_pre] = KbCheck(); %waits for space bar to be pressed
            if Down_pre == 1 && find(Code_pre) == KEY.rt
                Screen('DrawTexture',w,practpic2,[],STIM.imgrect);
                DrawFormattedText(w,'X\n\nDo not press if you do not hear a beep!','center','center',COLORS.RED)
                Screen('Flip',w);
                WaitSecs(2);
                Screen('Flip',w);
            elseif telap_prac > 1.5
                Screen('DrawTexture',w,practpic2,[],STIM.imgrect);
                DrawFormattedText(w,'Good work! DO NOT press the space bar when you do not hear a beep','center',YCENTER+330,COLORS.GREEN);
                Screen('Flip',w);
                WaitSecs(5);
                prac_corr2 = 1;
                break
            end
        end
    end
            
          
end



%% Task

for block = 1:STIM.blocks;
    %Load pics block by block.
    DrawPics4Block(block);
    ibt = sprintf('Prepare for Block %d.\n\nPress enter when you are ready to begin.',block);
    DrawFormattedText(w,ibt,'center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait([],2);

    PsychPortAudio('FillBuffer', pahandle, wave);
    old = Screen('TextSize',w,80);
    for trial = 1:STIM.trials;
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        Screen('Flip',w);
        WaitSecs(.5);
        
        [RespST.data.rt(trial,block), RespST.data.correct(trial,block)] = DoPicRespST(trial,block);
        %Wait 500 ms
        Screen('Flip',w);
        WaitSecs(.5);
    end
    Screen('TextSize',w,old);
    %Inter-block info here, re: Display accuracy & RT.
    Screen('Flip',w);   %clear screen first.
    
    block_text = sprintf('Block %d Results',block);
    
    c = RespST.data.correct(:,block) == 1;                                 %Find correct trials
%     corr_count = sprintf('Number Correct:\t%d of %d',length(find(c)),STIM.trials);  %Number correct = length of find(c)
    corr_per = length(find(c))*100/STIM.trials;                           %Percent correct = length find(c) / total trials
%     corr_pert = sprintf('Percent Correct:\t%4.1f%%',corr_per);          %sprintf that data to string.
    
    if isempty(c(c==1))
        %Don't try to calculate avg RT, they got them all wrong (WTF?)
        %Display "N/A" for this block's RT.
%         ibt_rt = sprintf('Average RT:\tUnable to calculate RT.');
        fulltext = sprintf('Number Correct:        %d of %d\nPercent Correct:        %4.1f%%\nAverage RT:        Unable to calculate due to 0 correct trials.',length(find(c)),STIM.trials,corr_per);
    else
        block_go = RespST.var.GoNoGo(:,block) == 1;                        %Find go trials
        blockrts = RespST.data.rt(:,block);                                %Pull all RT data
        blockrts = blockrts(c & block_go);                              %Resample RT only if go & correct.
        RespST.data.avg_rt(block) = fix(mean(blockrts)*1000);                        %Display avg rt in milliseconds.
        fulltext = sprintf('Number Correct:        %d of %d\nPercent Correct:        %4.1f%%\nAverage Rt:            %3d milliseconds',length(find(c)),STIM.trials,corr_per,RespST.data.avg_rt(block));
    end
    
    ibt_xdim = wRect(3)/10;
    ibt_ydim = wRect(4)/4;
    DrawFormattedText(w,block_text,'center',wRect(4)/10,COLORS.WHITE);   %Next lines display all the data.
    DrawFormattedText(w,fulltext,ibt_xdim,ibt_ydim,COLORS.WHITE,[],[],[],1.5);
    
    if block > 1
        % Also display rest of block data summary
        tot_trial = block * STIM.trials;
        totes_c = RespST.data.correct == 1;
%         corr_count_totes = sprintf('Number Correct: \t%d of %d',length(find(totes_c)),tot_trial);
        corr_per_totes = length(find(totes_c))*100/tot_trial;
%         corr_pert_totes = sprintf('Percent Correct:\t%4.1f%%',corr_per_totes);
        
        if isempty(totes_c(totes_c ==1))
            %Don't try to calculate RT, they have missed EVERY SINGLE GO
            %TRIAL! 
            %Stop task & alert experimenter?
            fullblocktext = sprintf('Number Correct:\t\t%d of %d\nPercent Correct:\t\t%4.1f%%\nAverage RT:\tUnable to calculate RT due to 0 correct trials.',length(find(totes_c)),tot_trial,corr_per_totes);            
        else
            tot_go = RespST.var.GoNoGo == 1;
            totrts = RespST.data.rt;
            totrts = totrts(totes_c & tot_go);
            avg_rt_tote = fix(mean(totrts)*1000);     %Display in units of milliseconds.
            fullblocktext = sprintf('Number Correct:\t\t%d of %d\nPercent Correct:\t\t%4.1f%%\nAverage RT:\t\t\t%3d milliseconds',length(find(totes_c)),tot_trial,corr_per_totes,avg_rt_tote);
        end
        
        DrawFormattedText(w,'Total Results','center',YCENTER,COLORS.WHITE);
        DrawFormattedText(w,fullblocktext,ibt_xdim,YCENTER+40,COLORS.WHITE,[],[],[],1.5);
    end
    
    Screen('Flip',w,[],1);
    WaitSecs(5);
    DrawFormattedText(w,'Press any key to continue.','center',wRect(4)*9/10,COLORS.WHITE);
    Screen('Flip',w);
    KbWait([],2);
%     Screen('TextSize',w,old);
    
        
    
end

%% Save all the data

%Export RespST to text and save with subject number.
%find the mfilesdir by figuring out where Veling_RespST.m is kept
[mfilesdir,~,~] = fileparts(which('RespST.m'));

%get the parent directory, which is one level up from mfilesdir
%[parentdir,~,~] =fileparts(mfilesdir);
savedir = [mfilesdir filesep 'Results' filesep];
savename = ['RespST_' num2str(ID) '.mat'];


if exist(savename,'file') == 2;
    savename = ['ResST' num2str(ID) sprintf('%s_%2.0f%02.0f',date,d(4),d(5)) '.mat'];
end
    
try
    save([savedir savename],'RespST');    
    
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        save([mfilesdir filesep savename],'RespST');
    catch
        warning('STILL problems saving....Try right-clicking on "b" in the "workspace" and Save as...');
        save RespST
    end
end

DrawFormattedText(w,'Thank you for participating\n in this part of the study!\n\nThe assessor will be with you shortly.','center','center',COLORS.WHITE);
Screen('Flip', w);
KbWait();

sca

end

%%
function [trial_rt, correct] = DoPicRespST(trial,block,varargin)
% tstart = tic;
% telap = toc(tstart);

global w STIM PICS COLORS RespST KEY pahandle

correct = -999;

trialduration = STIM.trialdur - RespST.var.delay(trial,block);

Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
pre_start = Screen('Flip',w);

    %First check for premature button pressing.
    pre = 0;
    prefail = 0;
    while pre < RespST.var.delay(trial,block);
        pre = GetSecs - pre_start;
        [Down_pre, ~, Code_pre] = KbCheck(); %waits for space bar to be pressed
        if Down_pre == 1 && find(Code_pre) == KEY.rt
            %Pressed too soon.
            trial_rt = pre_start - GetSecs() - RespST.var.delay(trial,block);      %This will show -X ms how early they were.
            Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
            DrawFormattedText(w,'X\n\nToo soon','center','center',COLORS.RED);
            prefail = 1;
            correct = 0;
            Screen('Flip',w');
            WaitSecs(.5);
            break
        else
            FlushEvents();
        end
    end

if prefail == 0;
    
    if RespST.var.GoNoGo(trial,block) == 1
        %If GoTone trial and you haven't pressed the button early, then RT is not from flip above, but from tone start.
        PsychPortAudio('Start', pahandle, 1);
    end
        RT_start = GetSecs();
 
    
    telap = 0;
    while telap < trialduration;
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck(); %waits for space bar to be pressed
        
        if Down == 1 && any(find(Code) == KEY.rt)
            trial_rt = GetSecs() - RT_start;
            
            if RespST.var.GoNoGo(trial,block) == 0;
                %This was incorrect press.
                Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
                DrawFormattedText(w,'X','center','center',COLORS.RED);
                correct = 0;
                Screen('Flip',w');
                WaitSecs(.5);
                break
            elseif RespST.var.GoNoGo(trial,block) == 1;
                %Correct press
                correct = 1;
                WaitSecs(.5);
                break;
            end
            FlushEvents();
        end
    end
    
    
    if correct == -999
        if RespST.var.GoNoGo(trial,block) == 0;    %If NoGo & Correct no press, do nothing & move to inter-trial black screen
            Screen('Flip',w);                   %'Flip in order to clear buffer; next 'flip' (in main script) flips to black screen.
            correct = 1;
        elseif RespST.var.GoNoGo(trial,block) == 1;
            Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
            DrawFormattedText(w,'X','center','center',COLORS.RED);
            Screen('Flip',w);
            correct = 0;
            WaitSecs(.5);
        end
        trial_rt = -999;
    end

end


end

%%
function DrawPics4Block(block,varargin)

global PICS RespST w

    for j = 1:length(RespST.var.trial_type);
        pic = RespST.var.picnum(j,block);
        switch RespST.var.trial_type(j,block)
            case {1}
                picn = getfield(PICS,'in','go',{pic},'name');
%                 PICS.out(j).raw = imread(getfield(PICS,'in','go',{pic},'name'));
%                 %I think this is is covered outside of switch/case
%                 PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
            case {2}
                picn = getfield(PICS,'in','no',{pic},'name');
%                 PICS.out(j).raw = imread(getfield(PICS,'in','no',{pic},'name'));
            case {3}
                picn = getfield(PICS,'in','neut',{pic},'name');
%                 PICS.out(j).raw = imread(getfield(PICS,'in','neut',{pic},'name'));
        end
        RespST.data.picname(j,block) = {picn};
        PICS.out(j).raw = imread(picn);
        PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
    end
%end
end

