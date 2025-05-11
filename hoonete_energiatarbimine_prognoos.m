% See skript treenib närvivõrgu mudeli hoonete energiatarbimise ennustamiseks
% sisenditeks on  ilmastikuandmed, nädalapäevad ja hoone pindalad
% tulemusena salvestatakse treenitud mudel hilisemaks kasutamiseks

clc; clear;

%hoonete pindalade defineerimine (m2 ühikutes)
areaGLN = 1062.4;     %GLN hoone pindala
areaTIM = 642.0; %TIM hoone pindala
areaD04 = 4323.6; %D04 hoone pindala

%õppimiseks kasutatavate nädalate ja vastavate ilmastikufailide määratlemine
weeks = {
    % Jaanuari andmeperioodid
    struct('start', datetime(2023,1,2), 'end', datetime(2023,1,8,23,0,0), 'weatherFile', 'Tallinn 2023-01-01 to 2023-01-31.csv');
    struct('start', datetime(2023,1,16), 'end', datetime(2023,1,22,23,0,0), 'weatherFile', 'Tallinn 2023-01-01 to 2023-01-31.csv');

    %Veebruari andmeperioodid
    struct('start', datetime(2023,2,6), 'end', datetime(2023,2,12,23,0,0), 'weatherFile', 'Tallinn 2023-02-01 to 2023-02-28.csv');
    struct('start', datetime(2023,2,20), 'end', datetime(2023,2,26,23,0,0), 'weatherFile', 'Tallinn 2023-02-01 to 2023-02-28.csv');

    %Märtsi ja aprilli andmeperioodid
    struct('start', datetime(2023,3,13), 'end', datetime(2023,3,19,23,0,0), 'weatherFile', 'Tallinn 2023-03-01 to 2023-04-30.csv');
    struct('start', datetime(2023,4,3), 'end', datetime(2023,4,9,23,0,0), 'weatherFile', 'Tallinn 2023-03-01 to 2023-04-30.csv');

    %Mai andmeperioodid
    struct('start', datetime(2023,5,8), 'end', datetime(2023,5,14,23,0,0), 'weatherFile', 'Tallinn 2023-05-01 to 2023-05-31.csv');
    struct('start', datetime(2023,5,22), 'end', datetime(2023,5,28,23,0,0), 'weatherFile', 'Tallinn 2023-05-01 to 2023-05-31.csv');

    %Juuni andmeperioodid
    struct('start', datetime(2023,6,5), 'end', datetime(2023,6,11,23,0,0), 'weatherFile', 'Tallinn 2023-06-01 to 2023-06-30.csv');
    struct('start', datetime(2023,6,19), 'end', datetime(2023,6,25,23,0,0), 'weatherFile', 'Tallinn 2023-06-01 to 2023-06-30.csv');

    %Juuli ja augusti andmeperioodid
    struct('start', datetime(2023,7,10), 'end', datetime(2023,7,16,23,0,0), 'weatherFile', 'Tallinn 2023-07-01 to 2023-08-31.csv');
    struct('start', datetime(2023,8,14), 'end', datetime(2023,8,20,23,0,0), 'weatherFile', 'Tallinn 2023-07-01 to 2023-08-31.csv');

    %Septembri  andmeperioodid
    struct('start', datetime(2023,9,4), 'end', datetime(2023,9,10,23,0,0), 'weatherFile', 'Tallinn 2023-09-01 to 2023-09-30.csv');
    struct('start', datetime(2023,9,18), 'end', datetime(2023,9,24,23,0,0), 'weatherFile', 'Tallinn 2023-09-01 to 2023-09-30.csv');

    %Oktoobri andmeperioodid
    struct('start', datetime(2023,10,9), 'end', datetime(2023,10,15,23,0,0), 'weatherFile', 'Tallinn 2023-10-01 to 2023-10-31.csv');
    struct('start', datetime(2023,10,23), 'end', datetime(2023,10,29,23,0,0), 'weatherFile', 'Tallinn 2023-10-01 to 2023-10-31.csv');

    %Detsembri andmeperioodid
    struct('start', datetime(2023,12,4), 'end', datetime(2023,12,10,23,0,0), 'weatherFile', 'Tallinn 2023-12-01 to 2023-12-31.csv');
    struct('start', datetime(2023,12,11), 'end', datetime(2023,12,17,23,0,0), 'weatherFile', 'Tallinn 2023-12-01 to 2023-12-31.csv');
};

% sisendtabelite laadimine (GLN, TIM, D04 )
inputAll = readtable('Input_data_GLN_TIM_D04.csv', 'Delimiter', ';');

%väljundtabeli laadimine  (TEG hoone tegelik tarbimine)
outputAll = readtable('Output_data_TEG.csv', 'Delimiter', ';');

% stringide teisendamine  arvulisteks väärtusteks  sisendtabelites
for col = {'GLN', 'TIM', 'D04'}
    inputAll.(col{1}) = str2double(strrep(string(inputAll.(col{1})), ',', '.'));
end
outputAll.TEG = str2double(strrep(string(outputAll.TEG), ',', '.'));

%ajatemplite loomine perioodi ja kellaaja veergudest
inputAll.FullTime = datetime(inputAll.Periood, 'InputFormat', 'dd.MM.yyyy') + duration(inputAll.time);
outputAll.FullTime = datetime(outputAll.Periood, 'InputFormat', 'dd.MM.yyyy') + duration(outputAll.time);

%Andmete ühendamise ja  tunnuste kogumise  aalustamine
X = []; % sisendtunnuste maatriks
Y = []; % väljundite vektor

%iga nädala andmete töötlemine eraldi tsüklis
for i = 1:numel(weeks)
    s = weeks{i}.start; %nädala  algusaeg
    e = weeks{i}.end; %nädala lõpuaeg
    w = readtable(weeks{i}.weatherFile); % vastava nädala ilmatabeli laadimine
    w.datetime = datetime(w{:,1}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
    w.FullTime = w.datetime;

   %filtreerime ainult valitud  nädalale vastavad  read
    iData = inputAll(inputAll.FullTime >= s & inputAll.FullTime <= e, :);
    oData = outputAll(outputAll.FullTime >= s & outputAll.FullTime <= e, :);
    wData = w(w.FullTime >= s & w.FullTime <= e, :);

    %ühendame tabelid ajatemplite alusel
    joined = innerjoin(iData, wData, 'Keys', 'FullTime');
    joined = innerjoin(joined, oData(:, {'TEG', 'FullTime'}), 'Keys', 'FullTime');

   %Hoonete energiakasutus korrutatakse pindalaga (normaliseerimiseks)
    areaF = [joined.GLN * areaGLN, joined.TIM * areaTIM, joined.D04 * areaD04];

     %ajaandmete  ja ilmaandmete põhjal sisendtunnuste moodustamine
    otherF = [hour(joined.FullTime), weekday(joined.FullTime), ...
              joined.temp, joined.humidity, joined.precip, ...
              joined.cloudcover, joined.windspeed];

    %tunnuste ja väljundite koondamine üldmassiividesse
    X = [X; areaF, otherF];
    Y = [Y; joined.TEG];
end

% sisendtunnuste normaliseerimine (kõik välja arvatud pindalad)
Xnorm = [X(:,1:3), normalize(X(:,4:end), 'range', [-1, 1])];
%väljundite min ja max väärtuste salvestamine skaleerimiseks
minY = min(Y);
maxY = max(Y);

%väljundite normaliseerimine vahemikku [-1, 1]
Ynorm = normalize(Y, 'range', [-1, 1]) ;

%närvivõrgu loomine määratud kihistruktuuriga
net = feedforwardnet([40, 30, 10]); %sisendkiht
net.trainFcn = 'trainlm'; % kasutatakse Levenberg-Marquardt algoritmi
net.divideParam.trainRatio = 1; % kogu andmestik läheb treeninguks
net.divideParam.valRatio = 0; %valideerimist ei kasutata
net.divideParam.testRatio = 0; %testkomplekti ei kasutata
net.trainParam.epochs = 1000; %maksimaalne epohhide  arv
net.trainParam.max_fail = 30;%maksimaalne lubatud valideerimisviga

%võrgu treenimine sisendtunnuste ja  väljundite põhjal
[net, tr] = train(net, Xnorm', Ynorm');

%prognoositud väärtuste teisendamine tagasi  algsele skaalale
Yhat = rescale(net(Xnorm'), minY, maxY);

%vektori  kuju vastavusse viimine
err = Y - Yhat';

%prognoosivea kvantitatiivne hindamine
mseError = mean(err.^2); %keskmine ruutviga
maeError = mean(abs(err)); %keskmine absoluutne viga
meanError = mean(err); % keskmine kallutatus
R2 = 1 - sum(err.^2) / sum((Y - mean(Y)).^2); %R-ruut  ( determinatsioonikordaja)
%tulemuste kuvamine  käsureal
fprintf('\nTäpsuse hinnangud:\n');
fprintf('MSE: %.4f |  MAE: %.4f | ME: %.4f | R^2: %.4f\n', mseError, maeError, meanError, R2);
fprintf('Prognoositav tarbimine: %.2f … %.2f kWh\n', min(Yhat), max(Yhat));

%treenitud võrgu ning skaleerimisparameetrite salvestamine faili
save('trainedModel.mat', 'net', 'minY', 'maxY');
fprintf('Mudel salvestatud: trainedModel.mat\n') ;
