% prognoositakse  MEK hoone energiatarbimist eri aastaaegadel ja võrreldakse tegelike andmetega
clc;
clear;

%Hoone pindala  (MEK) ruutmeetrites
newArea = 4434;

%laetakse eelnevalt treenitud närvivõrk ja väljundi skaleerimise piirid
load('trainedModel.mat', 'net', 'minY', 'maxY');

% MEK hoone tegelike tarbimisandmete laadimine
data = readtable('Data_MEK.csv', 'Delimiter', ';');
data.Timestamp = datetime(data.Timestamp, 'InputFormat', 'dd.MM.yyyy HH:mm');
data.MEK = str2double(strrep(data.MEK, ',', '.'));

% määratakse hooajad  ja vastavad ilmatikufailid
seasons = {
    'Talv',  datetime(2023,12,3), datetime(2023,12,9,23,0,0), 'Tallinn 2023-12-01 to 2023-12-31.csv';
    'Kevad', datetime(2023,3,19), datetime(2023,3,25,23,0,0), 'Tallinn 2023-03-01 to 2023-04-30.csv';
    'Suvi',  datetime(2023,7,23), datetime(2023,7,29,23,0,0), 'Tallinn 2023-07-01 to 2023-08-31.csv';
    'Sügis', datetime(2023,10,22),datetime(2023,10,28,23,0,0), 'Tallinn 2023-10-01 to 2023-10-31.csv';
};

% luuakse figuur hooajapõhise prognoosi kuvamiseks
figure;
for i = 1:size(seasons, 1)
    season = seasons{i,1};
    startDate = seasons{i,2};
    endDate   = seasons{i,3};
    fileName  = seasons{i,4};

 %ilmastikuandmete faili olemasolu kontroll
    if ~isfile(fileName)
        warning('Fail puudub: %s', fileName);
        continue;
    end

    %ilmaandmete lugemine ja ajavahemikuga filtreerimine
    weather = readtable(fileName);
    weather.datetime = datetime(weather{:,1}, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss');
    weather = weather(weather.datetime >= startDate & weather.datetime <= endDate, :);

    n = height(weather);
    if n == 0
        continue;
    end

    % sisendtunnuste moodustamine: tund, nädalapäev, ilmastikuparameetrid
    hourVec = hour(weather.datetime);
    weekdayVec = weekday(weather.datetime);
    inputFeatures = [ ...
        zeros(n,1), newArea * ones(n,1), zeros(n,1), ...
        hourVec, weekdayVec, ...
        weather.temp, weather.humidity, ...
        weather.precip, weather.cloudcover, weather.windspeed];

   % ilmastikuandmete ja ajaandmete normaliseerimine (v.a pindala)
    inputNorm = inputFeatures;
    inputNorm(:,4:end) = normalize(inputFeatures(:,4:end), 'range', [-1, 1]);

    %võrgu põhine tarbimise prognoos
     outputPred = net(inputNorm');

    % tulemuste teisendamine tagasi kWh skaalale
    outputPred = rescale(outputPred, minY, maxY);
    %tegelike MEK  tarbimisandmete filtreerimine valitud nädalale
    mask = data.Timestamp >= startDate & data.Timestamp <= endDate ;
    mek = data.MEK(mask);
    mek = mek(1:min(length(mek), length(outputPred)));

    % graafiku loomine –  tegelik vs prognoositud tarbimine
    subplot(2,2,i);
     plot(mek, 'k',  'LineWidth', 1.5); hold on;
    plot(outputPred(1:length(mek)), 'b', 'LineWidth', 1.5);
    title([season ' – MEK']);
    xlabel('Tund'); ylabel( 'Tarbimine (kWh)');
    legend('Tegelik', 'Prognoos');
    grid on;
end
% koondpealkiri kõikidele hooajapõhistele  joonistele
sgtitle('Prognoosi ja tegeliku tarbimise võrdlus – hoone MEK (4434 m^2)');
