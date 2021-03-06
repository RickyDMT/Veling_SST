function Veling_SST_fMRI(varargin)
% IF at BAKER, Blocks = ?, Trials = ?
% IF at LCNI, Blocks = ?, Trials = ?
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

prompt={'SUBJECT ID' 'Condition (1 or 2)' 'Session (1, 2, 3, or 4)' 'Practice? (1 = Y, 0 = N)' 'fMRI? (1 = Y, 0 = N)'};
defAns={'4444' '1' '1' '0' '1'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});
PRAC = str2double(answer{4});
fmri = str2double(answer{5});

fprintf('This is version 1.2: Faster jitter & no key presses for feedback screens.\n\n\n');

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
KEY.ONE= KbName('1!');
KEY.TWO= KbName('2@');
KEY.THREE= KbName('3#');
KEY.FOUR= KbName('4$');
KEY.FIVE= KbName('5%');
KEY.SIX= KbName('6^');
KEY.SEVEN= KbName('7&');
KEY.EIGHT= KbName('8*');
KEY.NINE= KbName('9(');
KEY.TEN= KbName('0)');
rangetest = cell2mat(struct2cell(KEY));
KEY.all = rangetest;

if fmri == 1;
    KEY.rt_L = KbName('3#');
    KEY.rt_R = KbName('6^');
else
    KEY.rt_L = KbName('SPACE');
    KEY.rt_R = KbName('SPACE');
end
KEY.trigger = KbName('''');  %This is an apostrophe for PC...
% KEY.trigger = KbName('''"');


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
STIM.trials = 35;
STIM.gotrials = 120;
STIM.notrials = 120;
STIM.neutrials = 40;
STIM.trialdur = 1.250;
STIM.resultdur = 3; %CHANGE THIS LINE FOR FASTER/SLOWER RESULTS SCREEN
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

[mdir,~,~] = fileparts(which('Veling_SST_fMRI.m'));
% imgdir = [mdir filesep 'MasterPics'];

%Setup for testing;
% imgdir = '/Users/canelab/Documents/StudyTasks/MasterPics';
% picratefolder = '/Users/canelab/Documents/StudyTasks/MasterPics/Saved_Pic_Ratings';

%Setup for LCNI
imgdir = [mdir filesep 'MasterPics']; %LCNI
picratefolder = fullfile(mdir,'Ratings');   %Name of folder at LCNI

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
    %Pull in random images of food for control condition?
    
    go_pics = dir('Bird*');
    no_pics = dir('Flower*');
    PICS.in.go = struct('name',{go_pics(randperm(length(go_pics),60)).name});
    PICS.in.no = struct('name',{no_pics(randperm(length(no_pics),60)).name});
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
pic_div = fix(STIM.gotrials/60);
pic_rem = rem(STIM.gotrials,60);

gopi = randperm(60)';
nopi = randperm(60)';
if pic_div >= 2
    for div = 2:pic_div;
        gopi = [gopi; randperm(60)'];
        nopi = [nopi; randperm(60)'];
    end
end
gopi = [gopi; randperm(60,pic_rem)'];
nopi = [nopi; randperm(60,pic_rem)'];

shuffled((shuffled(:,1)==1),3) = gopi;
shuffled((shuffled(:,1)==2),3) = nopi;

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
%     SST.var.jitter = SST.var.jitter/10; %For testing!
%%
%check for repeat pics in a any block
for tt = 1:2    %For each trial type...
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
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end

Screen('Flip',w);
WaitSecs(1);

%% Instructions
DrawFormattedText(w,'You will see pictures with either a blue or gray border around them.\n\nPlease press the button under your index finger as quickly & accurately as you can\nBUT only if you see a BLUE bar around the image.\n\nDo not press if you see a gray bar.\n\n\nPress any key to continue.','center','center',COLORS.WHITE,50,[],[],1.5);
Screen('Flip',w);
% KbWait();
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end



%% Practice
if PRAC == 1;
%Add 1 = practice sort of thing? Or practice is mandatory...

DrawFormattedText(w,' First, let''s practice.\n\nPress any key to continue.','center','center',COLORS.WHITE,65);
Screen('Flip',w);
% KbWait([],2);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end



practpic = imread(getfield(PICS,'in','neut',{1},'name'));
practpic = Screen('MakeTexture',w,practpic);

oldtextsize = Screen('TextSize',w,20);

%GO PRACTICE
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
Screen('Flip',w);
WaitSecs(.1);

Screen('DrawTexture',w,practpic,[],STIM.imgrect);
Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
DrawFormattedText(w,'In this trial, press the button under your index finger since the frame is blue.','center',STIM.framerect(4)+1,COLORS.WHITE,70,[],[],1.25);
Screen('Flip',w);
WaitSecs(3);

Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, press the button under your index finger since the frame is blue.','center',STIM.framerect(4)+1,COLORS.WHITE,70,[],[],1.25);
DrawFormattedText(w,'Press the index finger button to continue.','center','center',COLORS.RED); 
Screen('Flip',w);
% KbWait([],2);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end



%NO GO PRACTICE
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
Screen('Flip',w);
WaitSecs(.1);

Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, DO NOT press the button, since the frame is gray.','center',STIM.framerect(4)+10,COLORS.WHITE);
Screen('Flip',w);
WaitSecs(5);

Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, DO NOT press the button, since the frame is gray.','center',STIM.framerect(4)+10,COLORS.WHITE);
DrawFormattedText(w,'Press the index finger button to continue.','center','center',COLORS.RED); 
Screen('Flip',w);
% KbWait([],2);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end


Screen('TextSize',w,oldtextsize);

%Now let's run a few trials?
DrawFormattedText(w,'Now let''s try some practice trials.\nPress any key to continue.','center','center',COLORS.WHITE);
Screen('Flip',w);
% KbWait([],2);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end



pracpics = dir('Bird*');
prac_pic_nums = randperm(length(pracpics),20);
prac_gonogo = BalanceTrials(length(prac_pic_nums),1,[1 0]);

for jjj = 1:length(prac_pic_nums);
    DrawFormattedText(w,'+','center','center',COLORS.WHITE);
    Screen('Flip',w);
    WaitSecs(.5);
    
    pracpic_t = imread(pracpics(prac_pic_nums(jjj)).name);
    pracpic_out = Screen('MakeTexture',w,pracpic_t);
    Screen('DrawTexture',w,pracpic_out,[],STIM.imgrect);
    Screen('Flip',w);
    
    switch prac_gonogo(jjj)
        case {1}
            Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
        case {0}
            Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
    end
    
    Screen('DrawTexture',w,pracpic_out,[],STIM.imgrect);
    WaitSecs(.1);
    RT_start = Screen('Flip',w);
    telap = GetSecs() - RT_start;
    correct = -999;
    
    while telap <= (STIM.trialdur - .1);
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck(); %waits for space bar to be pressed
        if Down == 1 && (any(find(Code) == KEY.rt_L) || any(find(Code)  == KEY.rt_R))
            
%             trial_rt = GetSecs() - RT_start;
            
            
            
            if prac_gonogo(jjj) == 0;
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
        
        if prac_gonogo(jjj) == 0;    %If NoGo & Correct no press, do nothing & move to inter-trial black screen
            Screen('Flip',w);                   %'Flip in order to clear buffer; next 'flip' (in main script) flips to black screen.
%             correct = 1;
        else
            %             Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
            %             DrawFormattedText(w,'Please Click Faster','center','center',COLORS.RED);
            DrawFormattedText(w,'X','center','center',COLORS.RED);
            Screen('Flip',w);
%             correct = 0;
            WaitSecs(.5);
        end
%         trial_rt = -999;
    end
    
end

DrawFormattedText(w,'We will now move to the actual task.','center','center',COLORS.WHITE);
Screen('Flip',w);
WaitSecs(3);

end

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
    ibt = sprintf('Prepare for Block %d.\n\nPress the index finger button to begin.',block);
    DrawFormattedText(w,ibt,'center','center',COLORS.WHITE);
    Screen('Flip',w);
%     KbWait([],2);
FlushEvents();
while 1
    [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
    if pracDown == 1 && any(pracCode(KEY.all))
        break
    end
end

    Screen('Flip',w);
    WaitSecs(1);

    old = Screen('TextSize',w,100);
    for trial = 1:STIM.trials;

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
    corr_per = length(find(c))*100/length(c);                           %Percent correct = length find(c) / total trials
    c_go = (c & SST.var.GoNoGo(:,block) == 1);
    
    if ~any(c_go)
        %Don't try to calculate avg RT, they got them all wrong (WTF?)
        %Display "N/A" for this block's RT.
%         ibt_rt = sprintf('Average RT:\tUnable to calculate RT due to 0 correct trials.');
        fulltext = sprintf('Number Correct:        %d of %d\nPercent Correct:        %4.1f%%\nAverage RT (on Blue trials):        Unable to calculate due to 0 correct Blue trials.',length(find(c)),STIM.trials,corr_per);

    else
%         block_go = SST.var.GoNoGo(:,block) == 1;                        %Find go trials
        blockrts = SST.data.rt(:,block);                                %Pull all RT data
        blockrts = blockrts(c_go);                              %Resample RT only if go & correct.
        SST.data.avg_rt(block) = fix(mean(blockrts)*1000);                        %Display avg rt in milliseconds.
%         ibt_rt = sprintf('Average RT:\t\t\t%3d milliseconds',SST.data.avg_rt(block));
        fulltext = sprintf('Number Correct:        %d of %d\nPercent Correct:        %4.1f%%\nAverage RT (on Blue trials):            %3d milliseconds',length(find(c)),STIM.trials,corr_per,SST.data.avg_rt(block));
        
    end
    
    ibt_xdim = wRect(3)/10;
    ibt_ydim = wRect(4)/4;

    DrawFormattedText(w,block_text,'center',wRect(4)/10,COLORS.WHITE);   %Next lines display all the data.
    DrawFormattedText(w,fulltext,ibt_xdim,ibt_ydim,COLORS.WHITE,[],[],[],1.5);
    
    if block > 1
        % Also display rest of block data summary
        tot_trial = block * STIM.trials;
        totes_c = SST.data.correct == 1;
        corr_per_totes = length(find(totes_c))*100/tot_trial;
        tot_go_c = (totes_c & SST.var.GoNoGo == 1);
        
        if ~any(tot_go_c)
            %Don't try to calculate RT, they have missed EVERY SINGLE GO
            %TRIAL! 
            fullblocktext = sprintf('Number Correct:     %d of %d\nPercent Correct:     %4.1f%%\nAverage RT (on Blue trials):     Unable to calculate RT due to 0 correct Blue trials.',length(find(totes_c)),tot_trial,corr_per_totes);            
        else
            totrts = SST.data.rt;
            totrts = totrts(tot_go_c);
            avg_rt_tote = fix(mean(totrts)*1000);     %Display in units of milliseconds.
            fullblocktext = sprintf('Number Correct:        %d of %d\nPercent Correct:        %4.1f%%\nAverage RT (on Blue trials):        %3d milliseconds',length(find(totes_c)),tot_trial,corr_per_totes,avg_rt_tote);
        end
        
        DrawFormattedText(w,'Total Results','center',YCENTER,COLORS.WHITE);
        DrawFormattedText(w,fullblocktext,ibt_xdim,YCENTER+40,COLORS.WHITE,[],[],[],1.5);
    end
    
%     DrawFormattedText(w,'Press any key to continue.','center',wRect(4)*9/10,COLORS.WHITE);
    Screen('Flip',w);
    WaitSecs(STIM.resultdur);

    %     KbWait();
%     FlushEvents();
%     while 1
%         [pracDown, ~, pracCode] = KbCheck(); %waits for R or L index button to be pressed
%         if pracDown == 1 && any(pracCode(KEY.all))
%             break
%         end
%     end
    
    Screen('Flip',w);
    
    
end

%% Save all the data

%Export SST to text and save with subject number.
%find the mfilesdir by figuring out where Veling_SST.m is kept
% [mfilesdir,~,~] = fileparts(which('Veling_SST.m'));

%get the parent directory, which is one level up from mfilesdir
%[parentdir,~,~] =fileparts(mfilesdir);
savedir = [mdir filesep 'Results' filesep];
savename = ['vfSST_' num2str(ID) '-' num2str(SESS) '.mat'];

if exist(savename,'file')==2;
    savename = ['vfSST' num2str(ID) sprintf('%s_%2.0f%02.0f',date,d(4),d(5)) '.mat'];
end
    
try
    save([savedir savename],'SST');
    
catch
    try
        warning('Something is amiss with this save. Retrying to save in: %s\n',mfilesdir);
        save([mdir filesep savename],'SST');
    catch
        warning('STILL problems saving....Will attempt to save the entire workspace wherever the computer currently is: %s\n',pwd);
        save SST
    end
end

DrawFormattedText(w,'Thank you for participating in this part of the study!\n\nThe assessor will be with you shortly','center','center',COLORS.WHITE,65);
Screen('Flip', w);
KbWait([],2);

sca

end

%%
function [trial_rt, correct] = DoPicSST(trial,block,varargin)
% tstart = tic;
% telap = toc(tstart);

global w STIM PICS COLORS SST KEY scan_sec

    Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
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

end

function jitter = HardCodeJitter()

jitter = [4,5,5,2,2,3,3,2;4,2,5,5,2,5,5,2;2,5,3,3,2,3,3,5;5,4,4,5,2,2,3,5;3,4,4,2,4,5,3,4;2,3,2,2,2,2,5,3;2,3,5,2,5,4,4,2;3,2,4,3,2,4,2,5;3,2,4,4,5,3,3,5;4,3,4,5,5,5,5,4;2,2,3,4,2,4,4,3;5,4,2,3,4,3,2,3;2,3,3,4,5,5,3,2;2,3,3,3,3,5,5,2;2,2,5,2,3,4,2,3;5,4,3,2,3,2,4,4;4,3,4,4,5,3,5,4;3,3,3,5,5,2,2,2;2,4,5,5,5,2,5,5;2,5,2,5,4,5,5,5;4,5,4,4,2,5,4,2;4,2,3,2,3,3,4,4;5,4,4,4,4,3,5,4;3,5,5,5,2,4,5,2;2,4,5,3,5,3,4,4;3,3,5,4,3,5,4,3;5,4,5,4,3,4,4,5;2,2,3,3,5,4,2,2;3,4,2,2,3,4,2,2;5,5,3,4,3,4,2,3;5,4,3,4,3,2,2,3;4,3,4,5,4,4,3,2;3,4,2,2,4,5,2,2;3,5,5,3,4,5,3,5;2,3,5,5,2,4,3,3];

end