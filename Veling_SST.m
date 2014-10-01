function Veling_SST(varargin)

global KEY COLORS w wRect XCENTER YCENTER PICS STIM SST trial

prompt={'SUBJECT ID'};
defAns={'4444'};

answer=inputdlg(prompt,'Please input subject info',1,defAns);

ID=str2double(answer{1});

%Get condition assignment

rng(ID); %Seed random number generator with subject ID

KEY = struct;
KEY.rt = KbName('SPACE'); %To end random trial selection
% KEY.one = KbName('1!'); 
% KEY.two = KbName('2@'); 
% KEY.tres = KbName('3#');
% KEY.four = KbName('4$'); 
% KEY.five = KbName('5%');
% KEY.six = KbName('6^');
% KEY.sev = KbName('7&'); 
% KEY.eight = KbName('8*'); 
% KEY.nine = KbName('9('); 
% KEY.zero = KbName('0)'); 
% KEY.yes = KbName('y'); 
% KEY.no = KbName('n');

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
STIM.trials = 32;
STIM.trialdur = 1.250;

% Load in pics
%This will be based off of condition: Control = bird, flowers, etc.
%Modulate based off of condition assignment
%Change PICS.in.XXXX to more bland names (Go, NoGo, Neut)
PICS =struct;
PICS.in.good = dir('*good.jpg');
PICS.in.bad = dir('*bad.jpg');
PICS.in.h2o = dir('*water.jpg');
picsfields = fieldnames(PICS.in);

SST = struct;

trial_types = [ones(14,1); repmat(2,14,1); repmat(3,4,1)]; %1 = good food; 2 = bad food; 3 = water
gonogo = [ones(14,1); zeros(14,1)];
gonogoh20 = BalanceTrials(sum(trial_types==3),1,[0 1]);
gonogo = [gonogo; gonogoh20];
%When appropriate pics are found, update these to randperm(length(Pics.in.good),14) where '14' is # of desired pics of each type per block
%NEEDS QUESTION ANSWERED: All pics once, or all pics randomly (sample w/replacement)
%ELK 9/30/14: All pics will be displayed once!
piclist = [randperm(length(PICS.in.good)) randperm(length(PICS.in.good))];
piclist = [piclist randperm(length(PICS.in.bad)) randperm(length(PICS.in.bad))];
piclist = [piclist randperm(length(PICS.in.h2o))]';
trial_types = [trial_types gonogo piclist];

for g = 1:STIM.blocks;
    shuffled = trial_types(randperm(size(trial_types,1)),:);
    SST.var.trial_type(1:STIM.trials,g) = shuffled(:,1);
    SST.var.picnum(1:STIM.trials,g) = shuffled(:,3);
    SST.var.GoNoGo(1:STIM.trials,g) = shuffled(:,2);
end
    SST.data.rt = [];
    SST.data.correct = [];


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
    Screen('Resolution',0,1024,768,[],32);
    
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
Screen('TextSize',w,20);

KbName('UnifyKeyNames');

%% Set frame size;
STIM.framerect = [XCENTER-330; YCENTER-330; XCENTER+330; YCENTER+330];

% %moved to block by block input; will be based on pre-determined, random
% %selection of images.
% for n = 1:length(picsfields);
%     curr_field = picsfields{n};
%     PICS.out.(curr_field).raw = [];
%     PICS.out.(curr_field).texture = [];
%     for g = 1:length(PICS.in.(curr_field));
%         %Load in raw with imread
%         PICS.out.(curr_field)(g).raw = imread(getfield(PICS,'in',curr_field,{g},'name'));
%         %Draw with MakeTexture
%         %IS THIS TOO HEAVY?
%         PICS.out.(curr_field)(g).texture = Screen('MakeTexture',w,PICS.out.(curr_field)(g).raw);
%     end
% end


%% Initial screen
DrawFormattedText(w,'The stop signal task is about to begin.\nPress any key to continue.','center','center',COLORS.WHITE);
Screen('Flip',w);
KbWait();
Screen('Flip',w);
WaitSecs(.5);

%% Instructions
DrawFormattedText(w,'You see pictures with either a blue or gray border around them.\nPlease the press the space bar as quickly & accurately as you can\nBUT only if you see a BLUE bar around the image.\nDo not press if you see a gray bar.\nPress any key to continue.','center','center',COLORS.WHITE,300);
Screen('Flip',w);
KbWait();

%% Task

for block = 1:STIM.blocks;
    %Load pics block by block.
    DrawPics4Block(block);
    ibt = sprintf('Prepare for Block %d',block);
    DrawFormattedText(w,ibt,'center','center',COLORS.WHITE);
    Screen('Flip',w);
    KbWait();
    
    for trial = 1:STIM.trials;
        [SST.data.rt(trial,block), SST.data.correct(trial,block)] = DoPicSST(trial,block);
        %Wait 500 ms
        Screen('Flip',w);
        WaitSecs(.5);
    end
    %Inter-block info here, re: RT, accuracy, etc.
end

sca

end

%%
function [trial_rt, correct] = DoPicSST(trial,block,varargin)
% tstart = tic;
% telap = toc(tstart);

global w STIM PICS COLORS SST KEY

%while telap <= STIM.trialdur
    Screen('DrawTexture',w,PICS.out(trial).texture); %x must be pointer to image.
%     telap = toc(tstart);
    Screen('Flip',w); 
    
    switch SST.var.GoNoGo(trial,block)
        case {1}
            Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
        case {0}
            Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
    end
    Screen('DrawTexture',w,PICS.out(trial).texture);
    WaitSecs(.1);
    RT_start = Screen('Flip',w);
    telap = GetSecs() - RT_start;
    correct = -999;
    
    while telap <= (STIM.trialdur - .1); 
        telap = GetSecs() - RT_start;
        [Down, ~, Code] = KbCheck(); %waits for space bar to be pressed
        if Down == 1 && find(Code) == KEY.rt
            trial_rt = GetSecs() - RT_start;
            
            Screen('DrawTexture',w,PICS.out(trial).texture);
            old = Screen('TextSize',w,60);
            if SST.var.GoNoGo(trial,block) == 0;
                Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
                DrawFormattedText(w,'X','center','center',COLORS.RED);
                Screen('TextSize',w,old);
                correct = 0;
            else
%                 Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
%                 DrawFormattedText(w,'+','center','center',COLORS.GREEN);
                correct = 1;
            end
            Screen('Flip',w');
            WaitSecs(.5);
            break;
        end
    end
    
    if correct == -999;
        Screen('DrawTexture',w,PICS.out(trial).texture);
        
        if SST.var.GoNoGo(trial,block) == 0;
            Screen('FrameRect',w,COLORS.NO,STIM.framerect,20);
%             DrawFormattedText(w,'+','center','center',COLORS.GREEN);
            Screen('Flip',w);
            correct = 1;
        else
            Screen('FrameRect',w,COLORS.GO,STIM.framerect,20);
            DrawFormattedText(w,'X','center','center',COLORS.RED);
            Screen('Flip',w);
            correct = 0;
        end
        WaitSecs(.5);
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
                PICS.out(j).raw = imread(getfield(PICS,'in','good',{pic},'name'));
                PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
            case {2}
                PICS.out(j).raw = imread(getfield(PICS,'in','bad',{pic},'name'));
            case {3}
                PICS.out(j).raw = imread(getfield(PICS,'in','h2o',{pic},'name'));
        end
        PICS.out(j).texture = Screen('MakeTexture',w,PICS.out(j).raw);
    end
%end
end

