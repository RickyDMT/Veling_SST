function Veling_SST(varargin)
% Developed by ELK based on Veling et al., 2014
% Contact: elk@uoregon.edu
% Download latest version at: github.com/RickyDMT/Veling_SST

% Dictionary:
%All variables and data are stored in a .mat structure called SST_###.mat.
%A script will be developed (12/5 = in development) to extract data to a
%csv or some similar format

%Variables:
%SST.var.trial_type: Tells you what pic type was displayed; 1 = Go pic
    %(e.g., lo cal food); 2 = NoGo (high cal food); 3 = Neutral (water)
%SST.var.picnum:  Which pic from list was chosen.
%SST.var.GoNoGo:  1 = go trial, 0 = no-go trial

%Data:
%All trial-by-trial data are arranged such that each column represents a
%block and each row represents a trial within that block.
%SST.data.rt: Reaction time. Initially all 0s. Correct & incorrect rts
    %stored in seconds. If appropriate non-press, value = -999.
%SST.data.correct: Designates if trial was correct. initially -999 (and so,
    %remains -999 if trials was not completed); 1 = correct; 0 = incorrect.
%SST.data.avg_rt: Average reaction time per block.
%SST.data.info: Basic info of subject, session, condition, etc.

global KEY COLORS w wRect XCENTER YCENTER PICS STIM SST trial scan_sec

prompt={'SUBJECT ID' 'Condition (1 or 2)' 'Session (1, 2, or 3)' 'Practice? (1 = Y, 0 = N)' 'fMRI? (1 = Y, 0 = N)'};
defAns={'4444' '1' '1' '0' '1'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});
PRAC = str2double(answer{4});
fmri = str2double(answer{5});

file_check = sprintf('SST_%d-%d.mat',ID,SESS);

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
if fmri == 1;
    KEY.rt_L = KbName('3#');
    KEY.rt_R = KbName('6^');
else
    KEY.rt_L = KbName('SPACE');
    KEY.rt_R = KbName('SPACE');
end
% KEY.trigger = KbName('''');  %This is an apostrophe for PC...
KEY.trigger = KbName('''"');


COLORS = struct;
COLORS.BLACK = [0 0 0];
COLORS.WHITE = [255 255 255];
COLORS.RED = [255 0 0];
COLORS.BLUE = [0 0 255];
COLORS.GREEN = [0 255 0];
COLORS.YELLOW = [255 255 0];
COLORS.GO = COLORS.BLUE';        %color of go rectangle
COLORS.NO = [192 192 192]';     %color of no rectangle


STIM = struct;
STIM.blocks = 8;
STIM.trials = 40;
STIM.gotrials = 140;
STIM.notrials = 140;
STIM.neutrials = 40;
STIM.trialdur = 1.250;
%STIM.jitter = [1 2 3];   %This is now hardcoded at end of .m file...

%% Keyboard stuff for fMRI...

%list devices
[keyboardIndices, productNames] = GetKeyboardIndices;

isxkeys=strcmp(productNames,'Xkeys');

xkeys=keyboardIndices(isxkeys);
macbook = keyboardIndices(strcmp(productNames,'Apple Internal Keyboard / Trackpad'));

%in case something goes wrong or the keyboard name isn?t exactly right
if isempty(macbook)
    macbook=-1;
end

%in case you?re not hooked up to the scanner, then just work off the keyboard
if isempty(xkeys)
    xkeys=macbook;
end

%% Find and load pics
%This is setup for LCNI computers, which has pics in a folder within folder
%that contains Veling_SST.m.  At ORI, there is a separate MasterPics folder
%which all .m files point to...

[mdir,~,~] = fileparts(which('Veling_SST.m'));
imgdir = [mdir filesep 'MasterPics'];
% imgdir = '/Users/canelab/Documents/StudyTasks/MasterPics';
picratefolder = fullfile(mdir,'Ratings');   %Name of folder at ORI
% Setup for ORI...
% [imgdir,~,~] = fileparts(which('MasterPics_PlaceHolder.m')); Setup for ORI
% picratefolder = fullfile(mdir,'Saved_Pic_Ratings');   %Name of folder at ORI
randopics = 0;

if COND == 1;
    try
        cd(picratefolder)
    catch
        error('Could not find and/or open the rating folder.');
    end
    
    filen = sprintf('PicRatings_CC_%d-1.mat',ID); %This only looks for ratings from initial session.
    try
        p = open(filen);
    catch
        warning('Could not find and/or open the rating file.');
        commandwindow;
        randopics = input('Would you like to continue with a random selection of images? [1 = Yes, 0 = No]');
        if randopics == 1
            cd(imgdir)
            p = struct;
            p.PicRating.H = dir('Healthy*');
            p.PicRating.U = dir('Unhealthy*');
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
% picsfields = fieldnames(PICS.in);

%Check if pictures are present. If not, throw error.
%Could be updated to search computer to look for pics...
if isempty(PICS.in.go) || isempty(PICS.in.no) || isempty(PICS.in.neut)
    error('Could not find pics. Please ensure pictures are found in a folder names IMAGES within the folder containing the .m task file.');
end

%% Set up trials and other stimulus parameters
SST = struct;

trial_types = [ones(STIM.gotrials,1); repmat(2,STIM.notrials,1); repmat(3,STIM.neutrials,1)];  %1 = go; 2 = no; 3 = neutral/variable
gonogo = [ones(STIM.gotrials,1); zeros(STIM.notrials,1)];                         %1 = go; 0 = nogo;
gonogoh20 = BalanceTrials(STIM.neutrials,1,[0 1]);     %For neutral, go & no go are randomized
gonogo = [gonogo; gonogoh20];
% jitter = BalanceTrials(length(gonogo),1,[STIM.jitter]);
% jitter = jitter(1:length(gonogo));

%Make long list of #s to represent each pic
piclist = NaN(length(gonogo),1);

trial_types = [trial_types gonogo piclist]; %jitter];
shuffled = trial_types(randperm(size(trial_types,1)),:);
shuffled((shuffled(:,1)==1),3) = [randperm(60)'; randperm(60)'; randperm(60,STIM.gotrials-120)'];
shuffled((shuffled(:,1)==2),3) = [randperm(60)'; randperm(60)'; randperm(60,STIM.notrials-120)'];
shuffled((shuffled(:,1)==3),3) = [randperm(20)'; randperm(20,STIM.neutrials-20)'];

for g = 1:STIM.blocks;
    row = ((g-1)*STIM.trials)+1;
    rend = row+STIM.trials - 1;
    SST.var.trial_type(1:STIM.trials,g) = shuffled(row:rend,1);
    SST.var.GoNoGo(1:STIM.trials,g) = shuffled(row:rend,2);
    SST.var.picnum(1:STIM.trials,g) = shuffled(row:rend,3);
    %SST.var.jitter(1:STIM.trials,g) = shuffled(row:rend,4); %Now hardcoded at end of .m
    
end

    SST.var.jitter = HardCodeJitter();
%%
%check for repeat pics in a any block
for tt = 1:3    %For each trial type...
    for b = 1:STIM.blocks;  %In each block...
        t = SST.var.trial_type(:,b) == tt;   %Check for trials of trial type t in block b
        t_l = length(find(t));              %Check how many trials there are of type t in block b
        clist = SST.var.picnum(t,b);            %Find all pic numbers for trial type t in block b
        cc = unique(clist);                     %What are unique pic numbers
        c_l = length(cc);                   %How many unique numbers are there
        diff = t_l - c_l;
        
        while diff > 0          %If there are more trials than unique numbers
            for v = 1:c_l;      %Go through every unique number....
                rep_loc = find(clist == cc(v));   %And find the location(s) of that unique number
                while length(rep_loc) > 1                          %If there multiple instances of that unqiue number...
                    for u = 2:length(rep_loc)                   %Go through each instance, starting with second.
                        newnum  = randperm(60,1);               %Randomly choose new number.
                        newcheck = length(find(cc == newnum));  %Check if that new number has been used all ready.
                        while newcheck > 0                      %Trapped in while loop until newnum is unique
                            newnum  = randperm(60,1);
                            newcheck = length(find(cc == newnum));
                        end
                        clist(rep_loc(u)) = newnum; %insert new number into c array...which later be put back into SST structure
                        
                        
                    end
                    cc = unique(clist);
                    rep_loc = find(clist == cc(v));
                end
                
            end
            SST.var.picnum(t,b) = clist;
            cc = unique(SST.var.picnum(t,b));                     %What are unique pic numbers
            c_l = length(cc);                                     %How many unique numbers are there
            diff = t_l - c_l;
            
        end
        
            
    end
end

%%
    SST.data.rt = zeros(STIM.trials, STIM.blocks);
    SST.data.correct = zeros(STIM.trials, STIM.blocks)-999;
    SST.data.avg_rt = zeros(STIM.blocks,1);
    SST.data.fix_onset = NaN(STIM.trials, STIM.blocks);
    SST.data.pic_onset = NaN(STIM.trials, STIM.blocks);
    SST.data.frame_onset = NaN(STIM.trials, STIM.blocks);
    SST.data.info.ID = ID;
    SST.data.info.cond = COND;               %Condtion 1 = Food; Condition 2 = animals
    SST.data.info.session = SESS;
    SST.data.info.date = sprintf('%s %2.0f:%02.0f',date,d(4),d(5));
    


commandwindow;

%%
%change this to 0 to fill whole screen
DEBUG=0;

%set up the screen and dimensions

%list all the screens, then just pick the last one in the list (if you have
%only 1 monitor, then it just chooses that one)
Screen('Preference', 'SkipSyncTests', 1)

screenNumber=max(Screen('Screens'));

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

%%
%you can set the font sizes and styles here
Screen('TextFont', w, 'Arial');
%Screen('TextStyle', w, 1);
Screen('TextSize',w,30);

KbName('UnifyKeyNames');

%% Set frame size * Pic Location & Size;
STIM.framerect = [XCENTER-330; YCENTER-330; XCENTER+330; YCENTER+330];
STIM.imgrect = STIM.framerect + [30; 30; -30; -30];

%% Initial screen
DrawFormattedText(w,'The stop signal task is about to begin.\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
KbWait();
Screen('Flip',w);
WaitSecs(1);

%% Instructions
DrawFormattedText(w,'You will see pictures with either a blue or gray border around them.\n\nPlease the press the space bar as quickly & accurately as you can\nBUT only if you see a BLUE bar around the image.\n\nDo not press if you see a gray bar.\n\n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
KbWait();

%% Practice
if PRAC == 1;
%Add 1 = practice sort of thing? Or practice is mandatory...

DrawFormattedText(w,' First, let''s practice.\n\nPress any key to continue.','center','center',COLORS.WHITE);
Screen('Flip',w);
KbWait([],2);

practpic = imread(getfield(PICS,'in','neut',{1},'name'));
practpic = Screen('MakeTexture',w,practpic);

%GO PRACTICE
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
Screen('Flip',w);
WaitSecs(.1);

Screen('DrawTexture',w,practpic,[],STIM.imgrect);
Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
DrawFormattedText(w,'In this trial, you would press the space bar as quickly as you could since the frame is blue.','center',STIM.framerect(4)+20,COLORS.WHITE);
Screen('Flip',w);
WaitSecs(3);

Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, you would press the space bar as quickly as you could since the frame is blue.\nPress the space bar to continue.','center',STIM.framerect(4)+20,COLORS.WHITE);
Screen('Flip',w);
KbWait([],2);

%NO GO PRACTICE
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
Screen('Flip',w);
WaitSecs(.1);

Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, DO NOT press the space bar, since the frame is gray.','center',STIM.framerect(4)+20,COLORS.WHITE);
Screen('Flip',w);
WaitSecs(5);

Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, DO NOT press the space bar, since the frame is gray.\nPress enter to continue.','center',STIM.framerect(4)+20,COLORS.WHITE);
Screen('Flip',w);
KbWait([],2);

end
%Now let's run a few trials?

%% Trigger

if fmri == 1;
    DrawFormattedText(w,'Synching with fMRI: Waiting for trigger','center','center',COLORS.WHITE);
    Screen('Flip',w);
    
    scan_sec = KbTriggerWait(KEY.trigger,xkeys);
else
    scan_sec = GetSecs();
end

%% Task

for block = 1:STIM.blocks;
    %Load pics block by block.
    DrawPics4Block(block);
    ibt = sprintf('Prepare for Block %d.\n\nPress enter to begin.',block);
    DrawFormattedText(w,ibt,'center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait([],2);
    Screen('Flip',w);
    WaitSecs(1);

    old = Screen('TextSize',w,100);
    for trial = 1:STIM.trials;
%         %Jitter
%             %Fixation?
%             %DrawFormattedText(w,'+','center','center',COLORS.WHITE);
%             %Screen('Flip',w);
%         WaitSecs(SST.var.jitter);
        DrawFormattedText(w,'+','center','center',COLORS.WHITE);
        fixon = Screen('Flip',w);
        SST.data.fix_onset(trial,block) = fixon - scan_sec;
        WaitSecs(SST.var.jitter(trial,block));
        
        [SST.data.rt(trial,block), SST.data.correct(trial,block)] = DoPicSST(trial,block);
        %Wait 500 ms
        Screen('Flip',w);
        WaitSecs(.5);
    end
    Screen('TextSize',w,old);
    %Inter-block info here, re: Display accuracy & RT.
    Screen('Flip',w);   %clear screen first.
    
    block_text = sprintf('Block %d Results',block);
    
    c = SST.data.correct(:,block) == 1;                                 %Find correct trials
%     corr_count = sprintf('Number Correct:\t%d of %d',length(find(c)),STIM.trials);  %Number correct = length of find(c)
    corr_per = length(find(c))*100/length(c);                           %Percent correct = length find(c) / total trials
%     corr_pert = sprintf('Percent Correct:\t%4.1f%%',corr_per);          %sprintf that data to string.
    
    if isempty(c(c==1))
        %Don't try to calculate avg RT, they got them all wrong (WTF?)
        %Display "N/A" for this block's RT.
%         ibt_rt = sprintf('Average RT:\tUnable to calculate RT due to 0 correct trials.');
        fulltext = sprintf('Number Correct:        %d of %d\nPercent Correct:        %4.1f%%\nAverage RT:        Unable to calculate due to 0 correct trials.',length(find(c)),STIM.trials,corr_per);

    else
        block_go = SST.var.GoNoGo(:,block) == 1;                        %Find go trials
        blockrts = SST.data.rt(:,block);                                %Pull all RT data
        blockrts = blockrts(c & block_go);                              %Resample RT only if go & correct.
        SST.data.avg_rt(block) = fix(mean(blockrts)*1000);                        %Display avg rt in milliseconds.
%         ibt_rt = sprintf('Average RT:\t\t\t%3d milliseconds',SST.data.avg_rt(block));
        fulltext = sprintf('Number Correct:        %d of %d\nPercent Correct:        %4.1f%%\nAverage Rt:            %3d milliseconds',length(find(c)),STIM.trials,corr_per,SST.data.avg_rt(block));
        
    end
    
    ibt_xdim = wRect(3)/10;
    ibt_ydim = wRect(4)/4;
%     old = Screen('TextSize',w,25);
    DrawFormattedText(w,block_text,'center',wRect(4)/10,COLORS.WHITE);   %Next lines display all the data.
%     DrawFormattedText(w,corr_count,ibt_xdim,ibt_ydim,COLORS.WHITE);
%     DrawFormattedText(w,corr_pert,ibt_xdim,ibt_ydim+40,COLORS.WHITE);    
%     DrawFormattedText(w,ibt_rt,ibt_xdim,ibt_ydim+80,COLORS.WHITE);
    DrawFormattedText(w,fulltext,ibt_xdim,ibt_ydim,COLORS.WHITE,[],[],[],1.5);
    
    if block > 1
        % Also display rest of block data summary
        tot_trial = block * STIM.trials;
        totes_c = SST.data.correct == 1;
%         corr_count_totes = sprintf('Number Correct: \t%d of %d',length(find(totes_c)),tot_trial);
        corr_per_totes = length(find(totes_c))*100/tot_trial;
%         corr_pert_totes = sprintf('Percent Correct:\t%4.1f%%',corr_per_totes);
        
        if isempty(totes_c(totes_c ==1))
            %Don't try to calculate RT, they have missed EVERY SINGLE GO
            %TRIAL! 
            %Stop task & alert experimenter?
%             tot_rt = sprintf('Block %d Average RT:\tUnable to calculate RT due to 0 correct trials.',block);
            fullblocktext = sprintf('Number Correct:     %d of %d\nPercent Correct:     %4.1f%%\nAverage RT:     Unable to calculate RT due to 0 correct trials.',length(find(totes_c)),tot_trial,corr_per_totes);            
        else
            tot_go = SST.var.GoNoGo == 1;
            totrts = SST.data.rt;
            totrts = totrts(totes_c & tot_go);
            avg_rt_tote = fix(mean(totrts)*1000);     %Display in units of milliseconds.
%             tot_rt = sprintf('Average RT:\t\t\t%3d milliseconds',avg_rt_tote);
            fullblocktext = sprintf('Number Correct:        %d of %d\nPercent Correct:        %4.1f%%\nAverage RT:        %3d milliseconds',length(find(totes_c)),tot_trial,corr_per_totes,avg_rt_tote);
        end
        
        DrawFormattedText(w,'Total Results','center',YCENTER,COLORS.WHITE);
        DrawFormattedText(w,fullblocktext,ibt_xdim,YCENTER+40,COLORS.WHITE,[],[],[],1.5);
%         DrawFormattedText(w,corr_count_totes,ibt_xdim,ibt_ydim+160,COLORS.WHITE);
%         DrawFormattedText(w,corr_pert_totes,ibt_xdim,ibt_ydim+200,COLORS.WHITE);
%         DrawFormattedText(w,tot_rt,ibt_xdim,ibt_ydim+210,COLORS.WHITE);
        %Screen('Flip',w);
    end

    DrawFormattedText(w,'Press any key to continue.','center',wRect(4)*9/10,COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    Screen('Flip',w);
    
    %XXX: Game like element
    %XXX: Make it engaging.
        
    
end

%% Save all the data

%Export SST to text and save with subject number.
%find the mfilesdir by figuring out where Veling_SST.m is kept
[mfilesdir,~,~] = fileparts(which('Veling_SST.m'));

%get the parent directory, which is one level up from mfilesdir
%[parentdir,~,~] =fileparts(mfilesdir);
savedir = [mfilesdir filesep 'Results' filesep];
savename = ['vSST_' num2str(ID) '-' num2str(SESS) '.mat'];

if exist(savename,'file')==2;
    savename = ['SST' num2str(ID) sprintf('%s_%2.0f%02.0f',date,d(4),d(5)) '.mat'];
end
    
try
    save([savedir savename],'SST');
    
catch
    warning('Something is amiss with this save. Retrying to save in a more general location...');
    try
        save([mfilesdir filesep savename],'SST');
    catch
        warning('STILL problems saving....Try right-clicking on "SST" and Save as...');
        SST
    end
end

DrawFormattedText(w,'Thank you for participating\n in this part of the study!','center','center',COLORS.WHITE);
Screen('Flip', w);
KbWait();

sca

end

%%
function [trial_rt, correct] = DoPicSST(trial,block,varargin)
% tstart = tic;
% telap = toc(tstart);

global w STIM PICS COLORS SST KEY scan_sec

%while telap <= STIM.trialdur
    Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
%     telap = toc(tstart);
    picon = Screen('Flip',w);
    
    switch SST.var.GoNoGo(trial,block)
        case {1}
            Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
        case {0}
            Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
    end
    Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
    WaitSecs(.1);
    RT_start = Screen('Flip',w);
    telap = GetSecs() - RT_start;
    correct = -999;
    
    while telap <= (STIM.trialdur - .1); 
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck(); %waits for space bar to be pressed
        if Down == 1 && (any(find(Code) == KEY.rt_L) || any(find(Code)  == KEY.rt_R))
            
            trial_rt = GetSecs() - RT_start;
            


            if SST.var.GoNoGo(trial,block) == 0;
%                 Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);

                DrawFormattedText(w,'X','center','center',COLORS.RED);
                Screen('Flip',w);
                correct = 0;
                WaitSecs(.5);
            else
%                 Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
%                 DrawFormattedText(w,'+','center','center',COLORS.GREEN);
                correct = 1;
            end
            break;
        end
    end
    
    if correct == -999;
%         Screen('DrawTexture',w,PICS.out(trial).texture);
        
        if SST.var.GoNoGo(trial,block) == 0;    %If NoGo & Correct no press, do nothing & move to inter-trial black screen
            Screen('Flip',w);                   %'Flip in order to clear buffer; next 'flip' (in main script) flips to black screen.
            correct = 1;
        else
%             Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
%             DrawFormattedText(w,'Please Click Faster','center','center',COLORS.RED);
            DrawFormattedText(w,'X','center','center',COLORS.RED);
            Screen('Flip',w);
            correct = 0;
            WaitSecs(.5);
        end
        trial_rt = -999;
    end
    
    SST.data.pic_onset(trial,block) = picon - scan_sec;
    SST.data.frame_onset(trial,block) = RT_start - scan_sec;

%end
end

%%
function DrawPics4Block(block,varargin)

global PICS SST w

    for j = 1:length(SST.var.trial_type);
        pic = SST.var.picnum(j,block);
        switch SST.var.trial_type(j,block)
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

function jitter = HardCodeJitter()

jitter = [5,7,6,7,6,5,5,6;6,5,7,3,3,5,7,7;5,6,5,6,7,3,6,5;5,3,3,6,5,6,4,6;6,4,5,6,5,7,4,4;4,7,3,4,6,6,7,4;5,4,7,7,3,5,6,4;7,7,4,4,7,6,4,5;4,5,6,4,4,5,6,7;7,5,6,3,4,5,6,5;3,3,5,6,4,5,4,7;4,5,6,3,5,3,4,6;5,3,4,3,6,5,4,6;7,7,3,6,7,6,3,5;7,4,3,3,7,6,6,7;4,3,4,6,3,5,6,7;6,7,6,5,7,6,4,5;5,4,4,7,3,4,6,5;6,4,5,3,7,5,5,5;5,6,6,5,4,5,4,6;5,7,5,6,4,4,6,4;4,5,4,7,6,7,7,5;5,7,7,6,4,5,6,5;4,7,7,7,3,3,6,3;7,5,6,3,4,3,4,7;7,5,7,3,6,6,3,5;6,7,6,3,6,6,6,5;6,7,3,3,5,7,5,6;4,7,6,3,5,7,5,5;6,4,5,3,5,5,6,5;5,7,7,4,7,5,3,4;6,5,5,5,3,3,3,6;7,7,7,7,3,6,6,5;5,5,3,6,5,6,3,4;7,3,5,6,3,6,7,6;6,7,4,6,5,3,3,5;4,7,7,6,4,3,5,6;6,4,5,5,5,7,3,7;3,3,4,7,4,6,5,3;3,5,3,4,3,4,6,5];

end