function Respond_Signal_Training(varargin)
% Developed by ELK based on Schonberg et al., 2014
% Contact: elk@uoregon.edu
% Download latest version at: github.com/RickyDMT/Respond_Signal_Training

%Needs rated pics added.


global KEY COLORS w wRect XCENTER YCENTER PICS STIM RespST trial pahandle

prompt={'SUBJECT ID' 'Condition (1 or 2)' 'Session (1, 2, or 3)'};
defAns={'4444' '' ''};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});

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
STIM.trials = 25;
STIM.totes = STIM.blocks*STIM.trials;
STIM.trialdur = 1.5;

%% Find and load pics
[imgdir,~,~] = fileparts(which('Respond_Signal_Training.m'));

try
    cd([imgdir filesep 'IMAGES'])
catch
    error('Could not find and/or open the IMAGES folder.');
end

PICS =struct;
if COND == 1;                   %Condtion = 1 is food. 
    PICS.in.go = dir('good*.jpg');
    PICS.in.no = dir('*bad*.jpg');
    PICS.in.neut = dir('*water*.jpg');
elseif COND == 2;               %Condition = 2 is not food (birds/flowers)
    PICS.in.go = dir('*bird*.jpg');
    PICS.in.no = dir('*flowers*.jpg');
    PICS.in.neut = dir('*mam*.jpg');
end
% picsfields = fieldnames(PICS.in);

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.go) || isempty(PICS.in.no) || isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Set up trials and other stimulus parameters
RespST = struct;

trial_types = [ones(length(PICS.in.go),1); repmat(2,length(PICS.in.no),1); repmat(3,length(PICS.in.neut),1)];  %1 = go; 2 = no; 3 = neutral/variable
gonogo = [ones(length(PICS.in.go),1); zeros(length(PICS.in.go),1)];                         %1 = go; 0 = nogo;
gonogoh20 = BalanceTrials(sum(trial_types==3),1,[0 1]);     %For neutral, go & no go are randomized
gonogo = [gonogo; gonogoh20];

%Make long list of #s to represent each pic
piclist = [1:length(PICS.in.go) 1:length(PICS.in.no) 1:length(PICS.in.neut)]';
delay = BalanceTrials(STIM.totes,1,[.2,.3,.4]);
delay = delay(1:length(trial_types));

trial_types = [trial_types gonogo piclist delay];

shuffled = trial_types(randperm(size(trial_types,1)),:);


for g = 1:STIM.blocks;
    row = ((g-1)*STIM.trials)+1;
    rend = row+STIM.trials - 1;
    RespST.var.trial_type(1:STIM.trials,g) = shuffled(row:rend,1);
    RespST.var.picnum(1:STIM.trials,g) = shuffled(row:rend,3);
    RespST.var.GoNoGo(1:STIM.trials,g) = shuffled(row:rend,2);
    RespST.var.delay(1:STIM.trials,g) = shuffled(row:rend,4);
end

    RespST.data.rt = zeros(STIM.trials, STIM.blocks);
    RespST.data.correct = zeros(STIM.trials, STIM.blocks)-999;
    RespST.data.avg_rt = zeros(STIM.blocks,1);
    RespST.data.info.ID = ID;
    RespST.data.info.cond = COND;               %Condtion 1 = Food; Condition 2 = animals
    RespST.data.info.session = SESS;
    RespST.data.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    
commandwindow;

%%
%change this to 0 to fill whole screen
DEBUG=1;

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
STIM.framerect = [XCENTER-330; YCENTER-330; XCENTER+330; YCENTER+330];


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

% %Add 1 = practice sort of thing? Or practice is mandatory...
% practpic = imread(getfield(PICS,'in','neut',{1},'name'));
% practpic = Screen('MakeTexture',w,practpic);
% practpic2 = imread(getfield(PICS,'in','neut',{2},'name'));
% practpic2 = Screen('MakeTexture',w,practpic2);
% PsychPortAudio('FillBuffer', pahandle, wave);
% 
% DrawFormattedText(w,' First, let''s practice.\n\nPress any key to continue.','center','center',COLORS.WHITE);
% Screen('Flip',w);
% KbWait([],2);
% 
% 
% %GO PRACTICE
% Screen('DrawTexture',w,practpic);
% Screen('Flip',w);
% WaitSecs(.300);
% PsychPortAudio('Start', pahandle, 1);
% WaitSecs(.5);
% 
% Screen('DrawTexture',w,practpic);
% DrawFormattedText(w,'In this trial, you would press the space bar as quickly as you could since you heard a beep.','center',YCENTER,COLORS.BLUE,60);
% Screen('Flip',w);
% WaitSecs(5);
% Screen('DrawTexture',w,practpic);
% DrawFormattedText(w,'In this trial, you would press the space bar as quickly as you could since you heard a beep.\n\nPress the space bar to continue.','center',YCENTER,COLORS.BLUE,60);
% Screen('Flip',w);
% 
% KbWait([],2);
% Screen('Flip',w);
% Screen('Flip',w);
% WaitSecs(2);
% 
% %NO GO PRACTICE
% DrawFormattedText(w,'Now let''s see one without a beep.','center','center',COLORS.WHITE);
% Screen('Flip',w);
% WaitSecs(3);
% 
% Screen('DrawTexture',w,practpic2);
% Screen('Flip',w);
% WaitSecs(1);
% Screen('DrawTexture',w,practpic2);
% DrawFormattedText(w,'In this trial, DO NOT press the space bar, since there was no beep.','center',YCENTER,COLORS.BLUE,60);
% Screen('Flip',w);
% WaitSecs(5);
% Screen('DrawTexture',w,practpic2);
% DrawFormattedText(w,'In this trial, DO NOT press the space bar, since there was no beep.\n\nPress enter to continue on to the task.','center',YCENTER,COLORS.BLUE,60);
% Screen('Flip',w);
% KbWait([],2);
% 
% %Now let's run a few trials?


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
    corr_count = sprintf('Number Correct:\t%d of %d',length(find(c)),STIM.trials);  %Number correct = length of find(c)
    corr_per = length(find(c))*100/STIM.trials;                           %Percent correct = length find(c) / total trials
    corr_pert = sprintf('Percent Correct:\t%4.1f%%',corr_per);          %sprintf that data to string.
    
    if isempty(c(c==1))
        %Don't try to calculate avg RT, they got them all wrong (WTF?)
        %Display "N/A" for this block's RT.
        ibt_rt = sprintf('Average RT:\tUnable to calculate RT.');
    else
        block_go = RespST.var.GoNoGo(:,block) == 1;                        %Find go trials
        blockrts = RespST.data.rt(:,block);                                %Pull all RT data
        blockrts = blockrts(c & block_go);                              %Resample RT only if go & correct.
        RespST.data.avg_rt(block) = fix(mean(blockrts)*1000);                        %Display avg rt in milliseconds.
        ibt_rt = sprintf('Average RT:\t\t\t%3d milliseconds',RespST.data.avg_rt(block));
    end
    
    ibt_xdim = wRect(3)/10;
    ibt_ydim = wRect(4)/4;
    old = Screen('TextSize',w,25);
    DrawFormattedText(w,block_text,'center',wRect(4)/10,COLORS.WHITE);   %Next lines display all the data.
    DrawFormattedText(w,corr_count,ibt_xdim,ibt_ydim,COLORS.WHITE);
    DrawFormattedText(w,corr_pert,ibt_xdim,ibt_ydim+30,COLORS.WHITE);    
    DrawFormattedText(w,ibt_rt,ibt_xdim,ibt_ydim+60,COLORS.WHITE);
    %Screen('Flip',w);
    
    if block > 1
        % Also display rest of block data summary
        tot_trial = block * STIM.trials;
        totes_c = RespST.data.correct == 1;
        corr_count_totes = sprintf('Number Correct: \t%d of %d',length(find(totes_c)),tot_trial);
        corr_per_totes = length(find(totes_c))*100/tot_trial;
        corr_pert_totes = sprintf('Percent Correct:\t%4.1f%%',corr_per_totes);
        
        if isempty(totes_c(totes_c ==1))
            %Don't try to calculate RT, they have missed EVERY SINGLE GO
            %TRIAL! 
            %Stop task & alert experimenter?
            tot_rt = sprintf('Block %d Average RT:\tUnable to calculate RT due to 0 correct trials.',block);
        else
            tot_go = RespST.var.GoNoGo == 1;
            totrts = RespST.data.rt;
            totrts = totrts(totes_c & tot_go);
            avg_rt_tote = fix(mean(totrts)*1000);     %Display in units of milliseconds.
            tot_rt = sprintf('Average RT:\t\t\t%3d milliseconds',avg_rt_tote);
        end
        
        DrawFormattedText(w,'Total Results','center',ibt_ydim+120,COLORS.WHITE);
        DrawFormattedText(w,corr_count_totes,ibt_xdim,ibt_ydim+150,COLORS.WHITE);
        DrawFormattedText(w,corr_pert_totes,ibt_xdim,ibt_ydim+180,COLORS.WHITE);
        DrawFormattedText(w,tot_rt,ibt_xdim,ibt_ydim+210,COLORS.WHITE);
        %Screen('Flip',w);
    end
    
    Screen('Flip',w,[],1);
    WaitSecs(5);
    DrawFormattedText(w,'Press any key to continue.','center',wRect(4)*9/10,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    Screen('TextSize',w,old);
    
        
    
end

%% Save all the data

%Export RespST to text and save with subject number.
%find the mfilesdir by figuring out where Veling_RespST.m is kept
[mfilesdir,~,~] = fileparts(which('RespST.m'));

%get the parent directory, which is one level up from mfilesdir
%[parentdir,~,~] =fileparts(mfilesdir);
savedir = [mfilesdir filesep 'Results' filesep];

if exist(savedir,'dir') == 0;
    % If savedir (the directory to save files in) does not exist, make it.
    mkdir(savedir);
end
    
try
    
    %create the paths to the other directories, starting from the parent
    %directory
    % savedir = [parentdir filesep 'Results\proDMT\'];
    %         savedir = [mfilesdir filesep 'Results' filesep];
    
    save([savedir 'RespST_' num2str(ID) '_' num2str(SESS) '.mat'],'RespST');
    
catch
    error('Although data was (most likely) collected, file was not properly saved. 1. Right click on variable in right-hand side of screen. 2. Save as RespST_#_#.mat where first # is participant ID and second is session #. If you are still unsure what to do, contact your boss, Kim Martin, or Erik Knight (elk@uoregon.edu).')
end

DrawFormattedText(w,'Thank you for participating\n in this part of the study!','center','center',COLORS.WHITE);
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

Screen('DrawTexture',w,PICS.out(trial).texture);
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
            Screen('DrawTexture',w,PICS.out(trial).texture);
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
        
        if Down == 1 && find(Code) == KEY.rt
            trial_rt = GetSecs() - RT_start;
            
            if RespST.var.GoNoGo(trial,block) == 0;
                %This was incorrect press.
                Screen('DrawTexture',w,PICS.out(trial).texture);
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
            Screen('DrawTexture',w,PICS.out(trial).texture);
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
                PICS.out(j).raw = imread(getfield(PICS,'in','go',{pic},'name'));
%                 %I think this is is covered outside of switch/case
%                 PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
            case {2}
                PICS.out(j).raw = imread(getfield(PICS,'in','no',{pic},'name'));
            case {3}
                PICS.out(j).raw = imread(getfield(PICS,'in','neut',{pic},'name'));
        end
        PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
    end
%end
end

