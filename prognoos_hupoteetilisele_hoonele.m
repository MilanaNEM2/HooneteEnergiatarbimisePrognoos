clc;
clear;
%  Uue hoone pindala
newArea = 1156.5;
% laetakse eelnevalt treenitud mudel
load('trainedModel.mat', 'net', 'minY', 'maxY');
% defitseeritakse aastaajad ja  nendega seotud ilmastikuandmete failid
seasons = {
    'Talv',  datetime(2023,12,3), datetime(2023,12,9,23,0,0), 'Tallinn 2023-12-01 to 2023-12-31.csv';
    'Kevad', datetime(2023,3,19), datetime(2023,3,25,23,0,0), 'Tallinn 2023-03-01 to 2023-04-30.csv';
    'Suvi',  datetime(2023,7,23), datetime(2023,7,29,23,0,0), 'Tallinn 2023-07-01 to 2023-08-31.csv';
    'Sügis', datetime(2023,10,22),datetime(2023,10,28,23,0,0), 'Tallinn 2023-10-01 to 2023-10-31.csv';
};
figure;
for i = 1:size(seasons,1)
    season = seasons{i,1};
    startDate = seasons{i,2};
    endDate   = seasons{i,3};
    fileName  = seasons{i,4};

  % Kontrollitakse, kas fail on olemas
    if ~isfile(fileName)
        error('Ilmafaili ei leitud: %s', fileName);
   end

% Ilmaandmete  laadimine
weather = readtable(fileName);
weather.datetime = datetime(weather{:,1}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
weather.FullTime = weather.datetime;
weatherWeek = weather(weather.FullTime >= startDate & weather.FullTime <= endDate, :); %valitakse andmed määratud ajavahemiku kohta
n = height(weatherWeek);
    if n == 0
        warning('Andmed  puuduvad hooajaks %s (%s)', season, fileName);
        continue;
    end
% Aja- ja ilma tunnuste määratlemine
 hourVec = hour(weatherWeek.FullTime);
    weekdayVec = weekday(weatherWeek.FullTime);

    % Площадь задаём только для TIM здание, другие нулевые
    areaFeatures = [ ...
        zeros(n,1), ...
        newArea * ones(n,1), ...
        zeros(n,1)];

    % Признаки, подлежащие нормализации
    variableFeatures = [ ...
        hourVec, ...
        weekdayVec, ...
        weatherWeek.temp, ...
        weatherWeek.humidity, ...
        weatherWeek.precip, ...
        weatherWeek.cloudcover, ...
        zeros(n,1)];  % если ветра нет — нули

% Andmete normaliseerimine
normVars = normalize(variableFeatures, 'range', [-1, 1]);
%Lõplik sisendvektor
inputNorm = [areaFeatures, normVars];
 % Ennustuse tegemine ja rescale
outputPred = net(inputNorm');
outputPred = rescale(outputPred, minY, maxY);  %ennustuse  skaleerimine tagasi algskaalale

 % Graafiku joonistamine
    subplot(2,2,i);
    plot(outputPred, 'LineWidth', 1.5);
    title([season ' (pindala: ' num2str(newArea) ' m²)']);
    xlabel('Tund');
    ylabel('Prognoos (kWh)');
    grid on;
end

sgtitle('Prognoos hüpoteetilisele hoonele neljal aastaajal');
