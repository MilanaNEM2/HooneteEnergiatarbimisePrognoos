% prognoositakse erineva pindalaga hoonete energiatarbimist ühe nädala ilmaandmete põhjal
clc;
clear;

%Laaditakse eelnevalt treenitud närvivõrgu mudell
load('trainedModel.mat', 'net');

% määratakse prognoositav ajavahemik
startDate = datetime(2023,12,3);% valitud on üks nädal detsembris
endDate = datetime(2023,12,9,23,0,0);
fileName  = 'Tallinn 2023-12-01 to 2023-12-31.csv';

% defineeritakse hoone pindalade variandid (m ruudus)
areas =  [500, 1000, 2000, 3000];

% kontrollitakse ilmafaili olemasolu
if ~isfile(fileName)
    error('Ilmafaili ei leitud: %s', fileName) ;
end

%loetakse ilmaandmed ja  teisendatakse ajatemplid
weather = readtable(fileName);
weather.datetime = datetime(weather{:,1}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
weather.FullTime = weather.datetime;

% filtreeritakse andmed  valitud ajavahemikule vastavaks
weatherWeek = weather(weather.FullTime >= startDate & weather.FullTime <= endDate, :);
n = height(weatherWeek);

%Kontrollitakse, kas andmeid on valitud nädalal olemas
if n == 0
    error('Valitud nädalal puuduvad ilmaandmed.');
end

% ajaomaduste eraldamine (tund ja nädalapäev)
hourVec = hour(weatherWeek.FullTime);
weekdayVec = weekday(weatherWeek.FullTime);

% sisendtunnuste moodustamine ilma- ja ajaandmete põhjal
% tuulekiirus puudub, kasutatakse nullvektorit
variableFeatures = [ ...
    hourVec, ...
    weekdayVec, ...
    weatherWeek.temp, ...
    weatherWeek.humidity, ...
    weatherWeek.precip, ...
    weatherWeek.cloudcover, ...
    zeros(n,1)];

% tunnuste normaliseerimine vahemikku [-1, 1], v.a pindala
normVars = normalize(variableFeatures, 'range', [-1, 1]);

% joonistatakse prognooside graafik
figure;
hold on;
colors = lines(length(areas));

% prognoositakse energiatarbimine iga pindala jaoks eraldi
for i = 1:length(areas)
    area = areas(i);

    % pindalaandmete määramine: kasutatakse ainult TIM hoonet
    areaFeatures = [ ...
        zeros(n,1), ...
        area * ones(n,1), ...
        zeros(n,1)];
%täielik sisendvektor võrgu jaoks
  inputNorm = [areaFeatures, normVars];
    outputPred = net(inputNorm');% võrgu abil tarbimise prognoosimine
    outputPred = rescale(outputPred, 0, 21);%prognooside teisendamine tagasi  skalale [0, 21] kWh
    % tulemuste joonistamine graafikule
    plot(outputPred, 'Color', colors(i,:), 'LineWidth', 1.5, ...
         'DisplayName', [num2str(area) ' m^2']);
end

% graafiku vormistamine
title('Prognoositud energiatarbimine ühe nädala lõikes erineva pindalaga hoonetele');
xlabel('Tund');
ylabel('Tarbimine (kWh)');
grid on;
legend('show');
