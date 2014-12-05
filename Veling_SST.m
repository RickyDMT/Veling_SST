function Veling_SST(varargin)
% Developed by ELK based on Veling et al., 2014
% Contact: elk@uoregon.edu
% Download latest version at: github.com/RickyDMT/Veling_SST


global KEY COLORS w wRect XCENTER YCENTER PICS STIM SST trial

prompt={'SUBJECT ID' 'Condition (1 or 2)' 'Session (1, 2, or 3)' 'Practice? (1 = Y, 0 = N)'};
defAns={'4444' '' '' '0'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});
COND = str2double(answer{2});
SESS = str2double(answer{3});
PRAC = str2double(answer{4});

file_check = sprintf('SST_%d_%d.mat',ID,SESS);

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
KEY.rt = KbName('SPACE'); %To end random trial selection


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
STIM.blocks = 10;
STIM.trials = 32;
STIM.gotrials = 140;
STIM.notrials = 140;
STIM.trialdur = 1.250;

%% Find and load pics
[imgdir,~,~] = fileparts(which('MasterPics_PlaceHolder.m'));
picratefolder = fullfile(imgdir,'SavingsRatings');

try
    cd(picratefolder)
catch
    error('Could not find and/or open the .');
end

filen = sprintf('PicRate_%03d.mat',ID);
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

cd(imgdir);
 

PICS =struct;
if COND == 1;                   %Condtion = 1 is food. 
%     PICS.in.go = dir('good*.jpg');
%     PICS.in.no = dir('*bad*.jpg');
    %Choose top 80 most appetizing pics)
    PICS.in.go = struct('name',{p.PicRating.go(1:80).name}');
    PICS.in.no = struct('name',{p.PicRating.no(1:80).name}');
    PICS.in.neut = dir('Water*');
    
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

trial_types = [ones(STIM.gotrials,1); repmat(2,STIM.notrials,1); repmat(3,length(PICS.in.neut),1)];  %1 = go; 2 = no; 3 = neutral/variable
gonogo = [ones(STIM.gotrials,1); zeros(STIM.notrials,1)];                         %1 = go; 0 = nogo;
gonogoh20 = BalanceTrials(sum(trial_types==3),1,[0 1]);     %For neutral, go & no go are randomized
gonogo = [gonogo; gonogoh20];
% jitter = BalanceTrials(length(gonogo),1,[1 2 3]);

%Make long list of #s to represent each pic
% piclist = [1:length(PICS.in.go) 1:length(PICS.in.no) 1:length(PICS.in.neut)]';
piclist = [randsample(80,STIM.gotrials,1)' randsample(80,STIM.notrials,1)' 1:length(PICS.in.neut)]';
trial_types = [trial_types gonogo piclist];
shuffled = trial_types(randperm(size(trial_types,1)),:);

for g = 1:STIM.blocks;
    row = ((g-1)*STIM.trials)+1;
    rend = row+STIM.trials - 1;
    SST.var.trial_type(1:STIM.trials,g) = shuffled(row:rend,1);
    SST.var.picnum(1:STIM.trials,g) = shuffled(row:rend,3);
    SST.var.GoNoGo(1:STIM.trials,g) = shuffled(row:rend,2);
end

    SST.data.rt = zeros(STIM.trials, STIM.blocks);
    SST.data.correct = zeros(STIM.trials, STIM.blocks)-999;
    SST.data.avg_rt = zeros(STIM.blocks,1);
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
STIM.imgrect = STIM.framerect + [50; 50; -50; -50];

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
DrawFormattedText(w,'In this trial, you would press the space bar as quickly as you could since the frame is blue.','center',YCENTER,COLORS.NO,60);
Screen('Flip',w);
WaitSecs(3);

Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, you would press the space bar as quickly as you could since the frame is blue.\n\nPress the space bar to continue.','center',YCENTER,COLORS.NO,60);
Screen('Flip',w);
KbWait([],2);

%NO GO PRACTICE
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
Screen('Flip',w);
WaitSecs(.1);

Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, DO NOT press the space bar, since the frame is gray.','center',YCENTER,COLORS.NO,60);
Screen('Flip',w);
WaitSecs(5);

Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
Screen('DrawTexture',w,practpic,[],STIM.imgrect);
DrawFormattedText(w,'In this trial, DO NOT press the space bar, since the frame is gray.\n\nPress enter to continue.','center',YCENTER,COLORS.NO,60);
Screen('Flip',w);
KbWait([],2);

end
%Now let's run a few trials?


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
    corr_count = sprintf('Number Correct:\t%d of %d',length(find(c)),STIM.trials);  %Number correct = length of find(c)
    corr_per = length(find(c))*100/length(c);                           %Percent correct = length find(c) / total trials
    corr_pert = sprintf('Percent Correct:\t%4.1f%%',corr_per);          %sprintf that data to string.
    
    if isempty(c(c==1))
        %Don't try to calculate avg RT, they got them all wrong (WTF?)
        %Display "N/A" for this block's RT.
        ibt_rt = sprintf('Average RT:\tUnable to calculate RT due to 0 correct trials.');
    else
        block_go = SST.var.GoNoGo(:,block) == 1;                        %Find go trials
        blockrts = SST.data.rt(:,block);                                %Pull all RT data
        blockrts = blockrts(c & block_go);                              %Resample RT only if go & correct.
        SST.data.avg_rt(block) = fix(mean(blockrts)*1000);                        %Display avg rt in milliseconds.
        ibt_rt = sprintf('Average RT:\t\t\t%3d milliseconds',SST.data.avg_rt(block));
    end
    
    ibt_xdim = wRect(3)/10;
    ibt_ydim = wRect(4)/4;
    old = Screen('TextSize',w,25);
    DrawFormattedText(w,block_text,'center',wRect(4)/10,COLORS.WHITE);   %Next lines display all the data.
    DrawFormattedText(w,corr_count,ibt_xdim,ibt_ydim,COLORS.WHITE);
    DrawFormattedText(w,corr_pert,ibt_xdim,ibt_ydim+40,COLORS.WHITE);    
    DrawFormattedText(w,ibt_rt,ibt_xdim,ibt_ydim+80,COLORS.WHITE);
    %Screen('Flip',w);
    
    if block > 1
        % Also display rest of block data summary
        tot_trial = block * STIM.trials;
        totes_c = SST.data.correct == 1;
        corr_count_totes = sprintf('Number Correct: \t%d of %d',length(find(totes_c)),tot_trial);
        corr_per_totes = length(find(totes_c))*100/tot_trial;
        corr_pert_totes = sprintf('Percent Correct:\t%4.1f%%',corr_per_totes);
        
        if isempty(totes_c(totes_c ==1))
            %Don't try to calculate RT, they have missed EVERY SINGLE GO
            %TRIAL! 
            %Stop task & alert experimenter?
            tot_rt = sprintf('Block %d Average RT:\tUnable to calculate RT due to 0 correct trials.',block);
        else
            tot_go = SST.var.GoNoGo == 1;
            totrts = SST.data.rt;
            totrts = totrts(totes_c & tot_go);
            avg_rt_tote = fix(mean(totrts)*1000);     %Display in units of milliseconds.
            tot_rt = sprintf('Average RT:\t\t\t%3d milliseconds',avg_rt_tote);
        end
        
        DrawFormattedText(w,'Total Results','center',ibt_ydim+120,COLORS.WHITE);
        DrawFormattedText(w,corr_count_totes,ibt_xdim,ibt_ydim+160,COLORS.WHITE);
        DrawFormattedText(w,corr_pert_totes,ibt_xdim,ibt_ydim+200,COLORS.WHITE);
        DrawFormattedText(w,tot_rt,ibt_xdim,ibt_ydim+210,COLORS.WHITE);
        %Screen('Flip',w);
    end
    
    Screen('Flip',w,[],1);
    WaitSecs(5);
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

if exist(savedir,'dir') == 0;
    % If savedir (the directory to save files in) does not exist, make it.
    mkdir(savedir);
end
    
try
    
    %create the paths to the other directories, starting from the parent
    %directory
    % savedir = [parentdir filesep 'Results\proDMT\'];
    %         savedir = [mfilesdir filesep 'Results' filesep];
    
    save([savedir 'SST_' num2str(ID) '_' num2str(SESS) '.mat'],'SST');
    
catch
    error('Although data was (most likely) collected, file was not properly saved. 1. Right click on variable in right-hand side of screen. 2. Save as SST_#_#.mat where first # is participant ID and second is session #. If you are still unsure what to do, contact your boss, Kim Martin, or Erik Knight (elk@uoregon.edu).')
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

global w STIM PICS COLORS SST KEY

%while telap <= STIM.trialdur
    Screen('DrawTexture',w,PICS.out(trial).texture,[],STIM.imgrect);
%     telap = toc(tstart);
    Screen('Flip',w); 
    
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
        if Down == 1 && find(Code) == KEY.rt
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

