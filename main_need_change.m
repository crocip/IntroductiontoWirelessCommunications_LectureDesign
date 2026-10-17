clear;
clc;
close all;

rng(1);        % 固定随机种子，方便重复实验

%% =========================================================
% 系统参数
% ==========================================================

sps  = 8;      % 每个符号的采样点数
beta = 0.35;   % 根升余弦滚降系数
span = 8;      % RRC滤波器长度：8个符号周期

%% =========================================================
% 产生两种脉冲成形滤波器
% ==========================================================

% ---------------------------------------------------------
% 矩形脉冲
% ---------------------------------------------------------

hRect = ones(1,sps);

% 单位能量归一化
hRect = hRect / sqrt(sum(abs(hRect).^2));


% ---------------------------------------------------------
% 根升余弦脉冲
% 直接按照RRC公式生成
% ---------------------------------------------------------

hRRC = myRRC(beta, span, sps);


%% =========================================================
% 可以画图比较矩形脉冲和根升余弦脉冲，观察区别，时域和频域的
% ==========================================================

figure;

subplot(2,1,1);

plot(hRect,'o-','LineWidth',1.1);

xlabel('Sample');
ylabel('Amplitude');

title('矩形脉冲滤波器（时域）');

grid on;


subplot(2,1,2);

plot(hRRC,'LineWidth',1.1);

xlabel('Sample');
ylabel('Amplitude');

title('根升余弦脉冲滤波器（时域）');

grid on;


% 频域比较（零相位）

Hrect = fftshift(fft(hRect,2048));

Hrrc  = fftshift(fft(hRRC,2048));

fAxis = (-1024:1023)/2048;   % 归一化频率（以采样率的一半为1）


figure;

subplot(2,1,1);

plot(fAxis,20*log10(abs(Hrect)+eps),'LineWidth',1.1);

hold on;

plot(fAxis,20*log10(abs(Hrrc)+eps),'LineWidth',1.1);

xlabel('Normalized Frequency');
ylabel('|H(f)| (dB)');

title('矩形脉冲与RRC脉冲幅度谱比较');

legend('Rectangular','RRC');

ylim([-60 5]);

grid on;


subplot(2,1,2);

plot(fAxis,unwrap(angle(Hrect)),'LineWidth',1.1);

hold on;

plot(fAxis,unwrap(angle(Hrrc)),'LineWidth',1.1);

xlabel('Normalized Frequency');
ylabel('Phase (rad)');

title('矩形脉冲与RRC脉冲相位谱比较');

legend('Rectangular','RRC');

grid on;


%% =========================================================
% 固定QPSK
% 比较矩形脉冲与RRC脉冲的完整通信过程
% ==========================================================

M = 4;

NbitDemo = 20000;

bitsDemo = randi([0 1],1,NbitDemo);

EbN0Demo = 6;

% ---------------------------------------------------------
% 矩形脉冲系统
% ---------------------------------------------------------

outRect = runCommunication( ...
    bitsDemo, ...
    M, ...
    hRect, ...
    sps, ...
    EbN0Demo);


% ---------------------------------------------------------
% RRC系统
% ---------------------------------------------------------

outRRC = runCommunication( ...
    bitsDemo, ...
    M, ...
    hRRC, ...
    sps, ...
    EbN0Demo);


fprintf('\n');
fprintf('========================================\n');
fprintf('QPSK：矩形脉冲与RRC比较\n');
fprintf('Eb/N0 = %.1f dB\n',EbN0Demo);
fprintf('========================================\n');

fprintf('矩形脉冲 BER = %.6e\n',outRect.ber);
fprintf('矩形脉冲 EVM = %.2f %%\n',outRect.evm);

fprintf('RRC脉冲  BER = %.6e\n',outRRC.ber);
fprintf('RRC脉冲  EVM = %.2f %%\n',outRRC.evm);

fprintf('========================================\n\n');


%% =========================================================
% 比较两种脉冲成形后的发送时域信号（可选）
% ==========================================================

Nshow = 15*sps;

figure;

subplot(2,1,1);

plot(real(outRect.txWave(1:Nshow)));

xlabel('Sample');
ylabel('I');

title('矩形脉冲成形后的QPSK发送波形');

grid on;


subplot(2,1,2);

plot(real(outRRC.txWave(1:Nshow)));

xlabel('Sample');
ylabel('I');

title('根升余弦脉冲成形后的QPSK发送波形');

grid on;


%% =========================================================
% 理想QPSK星座
% ==========================================================

figure;

scatter( ...
    real(outRRC.txSym(1:2000)), ...
    imag(outRRC.txSym(1:2000)), ...
    20,'filled');

xline(0,'--');
yline(0,'--');

xlabel('I');
ylabel('Q');

title('理想QPSK星座');

axis square;

xlim([-1.5 1.5]);
ylim([-1.5 1.5]);

grid on;


%% =========================================================
% 矩形脉冲与RRC接收星座比较
% ==========================================================

figure;

subplot(1,2,1);

scatter( ...
    real(outRect.rxSample(1:5000)), ...
    imag(outRect.rxSample(1:5000)), ...
    8,'filled');

xline(0,'--');
yline(0,'--');

xlabel('I');
ylabel('Q');

title(['矩形脉冲，Eb/N0=', ...
       num2str(EbN0Demo),' dB']);

axis square;

xlim([-2 2]);
ylim([-2 2]);

grid on;


subplot(1,2,2);

scatter( ...
    real(outRRC.rxSample(1:5000)), ...
    imag(outRRC.rxSample(1:5000)), ...
    8,'filled');

xline(0,'--');
yline(0,'--');

xlabel('I');
ylabel('Q');

title(['RRC脉冲，Eb/N0=', ...
       num2str(EbN0Demo),' dB']);

axis square;

xlim([-2 2]);
ylim([-2 2]);

grid on;


%% =========================================================
% 观察匹配滤波后的波形与抽样位置，可选
% ==========================================================

figure;

NsymbolShow = 15;

startIndex = outRRC.sampleIndex(1);

endIndex = startIndex + NsymbolShow*sps;

indexShow = startIndex:endIndex;

sampleShow = outRRC.sampleIndex( ...
    outRRC.sampleIndex <= endIndex);


subplot(2,1,1);

plot( ...
    indexShow, ...
    real(outRRC.rxMF(indexShow)), ...
    'LineWidth',1.1);

hold on;

stem( ...
    sampleShow, ...
    real(outRRC.rxMF(sampleShow)), ...
    'filled');

yline(0,'--');

xlabel('Sample');
ylabel('I');

title('RRC匹配滤波后的I路信号及抽样点');

legend('匹配滤波输出',...
       '符号抽样点',...
       '判决门限');

grid on;


subplot(2,1,2);

plot( ...
    indexShow, ...
    imag(outRRC.rxMF(indexShow)), ...
    'LineWidth',1.1);

hold on;

stem( ...
    sampleShow, ...
    imag(outRRC.rxMF(sampleShow)), ...
    'filled');

yline(0,'--');

xlabel('Sample');
ylabel('Q');

title('RRC匹配滤波后的Q路信号及抽样点');

legend('匹配滤波输出',...
       '符号抽样点',...
       '判决门限');

grid on;


%% =========================================================
% 矩形脉冲和RRC在AWGN下的BER比较
%
% 理想同步 + 匹配滤波条件下：
% 两者BER应该非常接近。
%
% 主要差别应该体现在频谱，而不是AWGN BER。
% ==========================================================

EbN0ListPulse = 0:2:10;

BERrect = zeros(size(EbN0ListPulse));

BERrrc = zeros(size(EbN0ListPulse));

NbitBER = 120000;

bitsBER = randi([0 1],1,NbitBER);


for ii = 1:length(EbN0ListPulse)

    tempRect = runCommunication( ...
        bitsBER, ...
        4, ...
        hRect, ...
        sps, ...
        EbN0ListPulse(ii));

    tempRRC = runCommunication( ...
        bitsBER, ...
        4, ...
        hRRC, ...
        sps, ...
        EbN0ListPulse(ii));

    BERrect(ii) = tempRect.ber;

    BERrrc(ii) = tempRRC.ber;

end


% QPSK理论BER
EbN0Linear = 10.^(EbN0ListPulse/10);

BERtheory = ...
    0.5*erfc(sqrt(EbN0Linear));


figure;

semilogy( ...
    EbN0ListPulse, ...
    BERrect, ...
    'o-', ...
    'LineWidth',1.2);

hold on;

semilogy( ...
    EbN0ListPulse, ...
    BERrrc, ...
    's-', ...
    'LineWidth',1.2);

semilogy( ...
    EbN0ListPulse, ...
    BERtheory, ...
    '--', ...
    'LineWidth',1.2);


xlabel('E_b/N_0 (dB)');
ylabel('BER');

title('矩形脉冲与RRC的QPSK BER比较');

legend( ...
    'Rectangular', ...
    'RRC', ...
    'QPSK Theory', ...
    'Location','southwest');

grid on;


%% =========================================================
% 固定RRC
% 比较不同调制阶数
%
% QPSK   : M = 4
% 16QAM  : M = 16
% 64QAM  : M = 64
% ==========================================================

MList = [4 16 64];

EbN0List = 0:2:20;

NbitPerf = 120000;

BER_M = zeros( ...
    length(MList), ...
    length(EbN0List));


for mm = 1:length(MList)

    Mtemp = MList(mm);

    ktemp = log2(Mtemp);

    % 确保bit数能够被每个符号bit数整除
    NbitCurrent = ...
        floor(NbitPerf/ktemp)*ktemp;

    bitsTemp = ...
        randi([0 1],1,NbitCurrent);


    for ii = 1:length(EbN0List)

        resultTemp = ...
            runCommunication( ...
            bitsTemp, ...
            Mtemp, ...
            hRRC, ...
            sps, ...
            EbN0List(ii));

        BER_M(mm,ii) = ...
            resultTemp.ber;

    end

end


%% =========================================================
% 不同调制阶数BER比较
% ==========================================================

figure;

semilogy( ...
    EbN0List, ...
    BER_M(1,:), ...
    'o-', ...
    'LineWidth',1.3);

hold on;

semilogy( ...
    EbN0List, ...
    BER_M(2,:), ...
    's-', ...
    'LineWidth',1.3);

semilogy( ...
    EbN0List, ...
    BER_M(3,:), ...
    '^-', ...
    'LineWidth',1.3);


xlabel('E_b/N_0 (dB)');
ylabel('BER');

title('RRC成形下不同调制阶数的BER性能');

legend( ...
    'QPSK', ...
    '16QAM', ...
    '64QAM', ...
    'Location','southwest');

grid on;


%% =========================================================
% 相同Eb/N0下不同调制阶数星座图比较，供参考
% ==========================================================

EbN0Const = 10;

figure;


for mm = 1:length(MList)

    Mtemp = MList(mm);

    ktemp = log2(Mtemp);

    NbitConst = ...
        floor(30000/ktemp)*ktemp;

    bitsConst = ...
        randi([0 1],1,NbitConst);

    resultConst = ...
        runCommunication( ...
        bitsConst, ...
        Mtemp, ...
        hRRC, ...
        sps, ...
        EbN0Const);


    subplot(1,3,mm);

    Npoint = ...
        min(5000,length(resultConst.rxSample));

    scatter( ...
        real(resultConst.rxSample(1:Npoint)), ...
        imag(resultConst.rxSample(1:Npoint)), ...
        6, ...
        'filled');

    xlabel('I');
    ylabel('Q');

    title([ ...
        num2str(Mtemp), ...
        '-QAM, Eb/N0=', ...
        num2str(EbN0Const), ...
        ' dB']);

    axis square;

    grid on;

end


%% =========================================================
% 输出不同调制阶数的BER结果，只是样例，供参考
% ==========================================================

fprintf('\n');
fprintf('===========================================\n');
fprintf('RRC下不同调制方式 BER\n');
fprintf('===========================================\n');

fprintf('Eb/N0(dB)      QPSK          16QAM         64QAM\n');

for ii = 1:length(EbN0List)

    fprintf( ...
        '%5.1f       %10.3e    %10.3e    %10.3e\n', ...
        EbN0List(ii), ...
        BER_M(1,ii), ...
        BER_M(2,ii), ...
        BER_M(3,ii));

end

fprintf('===========================================\n');


%% =========================================================
% 自定义RRC滤波器，供参考
% ==========================================================

function h = myRRC(beta, span, sps)

    t = -span/2 : 1/sps : span/2;

    h = zeros(size(t));

    for n = 1:length(t)

        tn = t(n);

        % t = 0
        if abs(tn) < 1e-12

            h(n) = ...
                1 + beta*(4/pi - 1);

        % t = +-T/(4*beta)
        elseif beta > 0 && ...
               abs(abs(tn) - 1/(4*beta)) < 1e-10

            h(n) = ...
                beta/sqrt(2) * ...
                ( ...
                (1+2/pi)*sin(pi/(4*beta)) + ...
                (1-2/pi)*cos(pi/(4*beta)) ...
                );

        else

            numerator = ...
                sin(pi*tn*(1-beta)) + ...
                4*beta*tn .* ...
                cos(pi*tn*(1+beta));

            denominator = ...
                pi*tn .* ...
                (1-(4*beta*tn).^2);

            h(n) = ...
                numerator ./ denominator;

        end

    end

    % 单位能量归一化
    h = h / sqrt(sum(abs(h).^2));

end


% =========================================================
% 完整通信链路（M-QAM Gray映射 -> RRC成形 -> AWGN -> 匹配滤波 -> 抽样 -> 判决）
% =========================================================

function out = runCommunication( ...
    bits, M, hTx, sps, EbN0dB)


    %% ------------------------------------------------------
    % 调制
    % -------------------------------------------------------

    txSym = myQAMMod(bits,M);

    Nsym = length(txSym);

    k = log2(M);


    %% ------------------------------------------------------
    % 上采样
    % -------------------------------------------------------

    txUp = zeros(1,Nsym*sps);

    txUp(1:sps:end) = txSym;


    %% ------------------------------------------------------
    % 脉冲成形
    % -------------------------------------------------------

    txWave = conv( ...
        txUp, ...
        hTx, ...
        'full');


    %% ------------------------------------------------------
    % AWGN
    %
    % 已经将平均符号能量归一化为：
    %
    % Es = 1
    %
    % Eb = Es / log2(M)
    % -------------------------------------------------------

    Es = 1;

    Eb = Es/k;

    EbN0 = 10^(EbN0dB/10);

    N0 = Eb/EbN0;


    noise = ...
        sqrt(N0/2) * ...
        ( ...
        randn(size(txWave)) + ...
        1j*randn(size(txWave)) ...
        );


    rxWave = ...
        txWave + noise;


    %% ------------------------------------------------------
    % 匹配滤波
    % -------------------------------------------------------

    hRx = ...
        conj(fliplr(hTx));

    rxMF = ...
        conv(rxWave,hRx,'full');


    %% ------------------------------------------------------
    % 计算匹配滤波峰值位置
    %
    % Tx滤波器 + Rx匹配滤波器
    %
    % 总延时 = length(hTx)-1
    % -------------------------------------------------------

    totalDelay = ...
        length(hTx)-1;


    %% ------------------------------------------------------
    % 符号抽样
    % -------------------------------------------------------

    sampleIndex = ...
        totalDelay + 1 + ...
        (0:Nsym-1)*sps;

    rxSample = ...
        rxMF(sampleIndex);


    %% ------------------------------------------------------
    % QAM判决解调
    % -------------------------------------------------------

    bitsHat = ...
        myQAMDemod(rxSample,M);


    %% ------------------------------------------------------
    % BER：统计误比特数（代码已补充完整）
    % -------------------------------------------------------

    Nbit = min(length(bits),length(bitsHat));

    bitsUsed = bits(1:Nbit);

    bitsHat = bitsHat(1:Nbit);

    bitErrors = sum(bitsUsed ~= bitsHat);

    BER = bitErrors/Nbit;

    %% ------------------------------------------------------
    % EVM
    % -------------------------------------------------------

    EVM = ...
        sqrt( ...
        mean(abs(rxSample-txSym).^2) / ...
        mean(abs(txSym).^2) ...
        )*100;


    %% ------------------------------------------------------
    % 输出
    % -------------------------------------------------------

    out.txSym = txSym;

    out.txWave = txWave;

    out.rxWave = rxWave;

    out.rxMF = rxMF;

    out.sampleIndex = sampleIndex;

    out.rxSample = rxSample;

    out.bitsHat = bitsHat;

    out.ber = BER;

    out.evm = EVM;

end


%% =========================================================
% Gray编码方形M-QAM调制
%
% 支持：
%
% M = 4
% M = 16
% M = 64
%
% 平均符号能量归一化为 Es = 1
% ==========================================================

function symbols = myQAMMod(bits,M)

    k = log2(M);

    L = sqrt(M);

    m = k/2;

    bits = bits(:).';

    Nsym = length(bits)/k;


    %% 每k个bit组成一个符号

    bitMatrix = ...
        reshape(bits,k,[]).';


    %% 前m位控制I

    bitsI = ...
        bitMatrix(:,1:m);


    %% 后m位控制Q

    bitsQ = ...
        bitMatrix(:,m+1:end);


    %% 二进制转整数

    weight = ...
        2.^((m-1):-1:0);

    binaryI = ...
        bitsI * weight.';

    binaryQ = ...
        bitsQ * weight.';


    %% Binary -> Gray

    grayI = ...
        bitxor( ...
        uint32(binaryI), ...
        bitshift(uint32(binaryI),-1));

    grayQ = ...
        bitxor( ...
        uint32(binaryQ), ...
        bitshift(uint32(binaryQ),-1));


    %% PAM电平

    levels = ...
        -(L-1):2:(L-1);


    I = ...
        levels(double(grayI)+1);

    Q = ...
        levels(double(grayQ)+1);


    I = I(:);

    Q = Q(:);


    %% QAM符号：I路为实部，Q路为虚部

    symbols = I + 1j*Q;


    %% ------------------------------------------------------
    % 平均符号能量归一化
    %
    % square M-QAM：
    %
    % Es = 2(M-1)/3
    %
    % -------------------------------------------------------

    normFactor = ...
        sqrt(2*(M-1)/3);

    symbols = ...
        symbols / normFactor;

    symbols = symbols.';

end


%% =========================================================
% Gray编码方形M-QAM解调（代码已补充完整）
% ==========================================================

function bitsHat = myQAMDemod(symbols,M)

    k = log2(M);

    m = k/2;

    L = sqrt(M);


    %% 恢复原始幅值

    normFactor = ...
        sqrt(2*(M-1)/3);

    symbols = ...
        symbols * normFactor;

    symbols = symbols(:);


    levels = ...
        -(L-1):2:(L-1);


    %% ------------------------------------------------------
    % 找距离最近的I/Q幅值（代码已补充完整）
    % -------------------------------------------------------
    %% 最近幅值判决

    Ivalue = real(symbols);

    Qvalue = imag(symbols);


    indexI = zeros(length(symbols),1);

    indexQ = zeros(length(symbols),1);



    for ii = 1:length(symbols)

        [~,indexI(ii)] = ...
            min(abs(Ivalue(ii)-levels));


        [~,indexQ(ii)] = ...
            min(abs(Qvalue(ii)-levels));

    end

    %% 索引对应的是Gray码整数

    grayI = ...
        uint32(indexI-1);

    grayQ = ...
        uint32(indexQ-1);


    %% Gray -> Binary

    binaryI = ...
        gray2binary(grayI);

    binaryQ = ...
        gray2binary(grayQ);


    %% 整数重新变成bit

    bitsI = ...
        zeros(length(symbols),m);

    bitsQ = ...
        zeros(length(symbols),m);


    for ii = 1:m

        bitPos = m-ii+1;

        bitsI(:,ii) = ...
            double(bitget(binaryI,bitPos));

        bitsQ(:,ii) = ...
            double(bitget(binaryQ,bitPos));

    end


    %% 合并I/Q bit

    bitMatrix = ...
        [bitsI bitsQ];

    bitsHat = ...
        reshape(bitMatrix.',1,[]);

end


%% =========================================================
% Gray整数 -> Binary整数
% ==========================================================

function binary = gray2binary(gray)

    binary = gray;

    temp = ...
        bitshift(gray,-1);


    while any(temp ~= 0)

        binary = ...
            bitxor(binary,temp);

        temp = ...
            bitshift(temp,-1);

    end

end


%% =========================================================
% 【扩展部分一】图3-4：RRC级联升余弦频谱（验证零ISI准则）
% 发送RRC + 接收匹配RRC 级联 = 升余弦(RC)响应，
% 在符号间隔上满足Nyquist第一准则（抽样点无ISI）。
% ==========================================================

figure;

subplot(2,1,1);

% 发送RRC与接收匹配RRC级联 = 升余弦(RC)组合响应（时域卷积）

gRC = conv(hRRC, conj(fliplr(hRRC)));          % RRC x RRC = RC 组合响应
GRC   = fftshift(fft(gRC,2048));

plot(fAxis, 20*log10(abs(GRC)+eps), 'LineWidth',1.2); hold on;
% 叠加理想升余弦谱作参照
omega  = abs(fAxis).*sps;  % 以符号率Rs为单位的归一化频率
rcIdeal = zeros(size(omega));
inFlat  = omega <= 1-beta;
inRoll  = (omega > 1-beta) & (omega <= 1+beta);
rcIdeal(inFlat) = 1;
rcIdeal(inRoll) = 0.5*(1+cos(pi*(omega(inRoll)-(1-beta))/(2*beta)));
plot(fAxis, 20*log10(rcIdeal+eps), '--', 'LineWidth',1.2);
xlabel('Normalized Frequency'); ylabel('|H_{RC}(f)| (dB)');
title(['级联升余弦频谱与理想RC对比（\beta=',num2str(beta),'）']);
legend('RRC级联实际谱','理想升余弦谱'); xlim([-0.5 0.5]); ylim([-60 3]); grid on;

subplot(2,1,2);
% 时域：组合冲激响应在整数符号间隔处抽样 -> 除中心点外均为0（无ISI）
peakIdx = (length(gRC)+1)/2;                          % gRC长度必为奇数，峰值居中
idxT = (-3*span*sps : 3*span*sps) + peakIdx;     % 以峰值为中心的对称索引
idxT = idxT(idxT>=1 & idxT<=length(gRC));
stem((idxT - peakIdx)/sps, real(gRC(idxT))/max(gRC), 'filled');
xlabel('t/T_s'); ylabel('g(t)');
title('级联RC冲激响应的符号间隔抽样（非中心抽样点≈0，即无ISI）');
grid on;


%% =========================================================
% 【扩展部分二】图3-5：矩形脉冲与RRC成形后发送信号的功率谱(PSD)
% 用Welch法估计，直观展示带外抑制差异（旁瓣泄漏 vs 快速滚降）。
% ==========================================================

Npsd  = 40000;                       % 更多符号使谱更平滑
bitsPsd = randi([0 1],1,Npsd*2);     % QPSK: 2 bit/sym

outRectPsd = runCommunication(bitsPsd, 4, hRect, sps, 30);  % 高Eb/N0近似无噪波形
outRrcPsd  = runCommunication(bitsPsd, 4, hRRC,  sps, 30);

figure;

[Prx,frx] = periodogram(real(outRectPsd.txWave), [], 4096, sps, 'centered');
[Psx,fsx] = periodogram(real(outRrcPsd.txWave),  [], 4096, sps, 'centered');

% 转成相对谱（dB），便于与滤波器幅度谱对照：0 dB = 带内峰值
PrxdB = 10*log10(Prx+eps); PrxdB = PrxdB - max(PrxdB);
Psxdb = 10*log10(Psx+eps); Psxdb = Psxdb - max(Psxdb);

plot(frx, PrxdB, 'LineWidth',1.1); hold on;
plot(fsx, Psxdb, 'LineWidth',1.1);
xlabel('Frequency (以符号率Rs为单位)'); ylabel('归一化PSD (dB)');
title('矩形脉冲与RRC成形后发送信号功率谱密度比较');
legend('矩形脉冲','RRC脉冲');
xlim([-2 2]); ylim([-60 3]); grid on;


%% =========================================================
% 【扩展部分三】图3-9：不同滚降系数 \beta 的RRC滤波器频谱对比
% 说明：\beta 决定已调信号带宽 B = (1+\beta)Rs/2，
%       \beta 越大 -> 频谱滚降越缓、占用带宽越大、时域拖尾越短。
% ==========================================================

betaList = [0.2 0.5 1.0];
colors   = lines(numel(betaList));

figure;

subplot(1,2,1);
for ib = 1:numel(betaList)
    hb = myRRC(betaList(ib), span, sps);
    Hb = fftshift(fft(hb,2048));
    plot(fAxis, 20*log10(abs(Hb)+eps), 'Color', colors(ib,:), 'LineWidth',1.2);
    hold on;
end
xlabel('Normalized Frequency'); ylabel('|H(f)| (dB)');
title('不同\beta的RRC幅度谱');
legend(arrayfun(@(b) sprintf('\\beta=%.1f',b), betaList,'UniformOutput',false));
xlim([-0.6 0.6]); ylim([-60 5]); grid on;

subplot(1,2,2);
for ib = 1:numel(betaList)
    hb = myRRC(betaList(ib), span, sps);
    gb = conv(hb, conj(fliplr(hb)));         % 级联RC谱
    Gb = fftshift(fft(gb,2048));
    plot(fAxis, 20*log10(abs(Gb)+eps), 'Color', colors(ib,:), 'LineWidth',1.2);
    hold on;
end
xline(-0.5*(1+betaList(1))/sps,'k--'); xline(0.5*(1+betaList(1))/sps,'k--');
xline(-0.5*(1+betaList(2))/sps,'k-.'); xline(0.5*(1+betaList(2))/sps,'k-.');
xline(-0.5*(1+betaList(3))/sps,'k:');  xline(0.5*(1+betaList(3))/sps,'k:');
xlabel('Normalized Frequency'); ylabel('|H_{RC}(f)| (dB)');
title('不同\beta的级联升余弦谱与带宽边界');
legend(arrayfun(@(b) sprintf('\\beta=%.1f',b), betaList,'UniformOutput',false), ...
       'Location','southwest');
xlim([-0.6 0.6]); ylim([-60 3]); grid on;


%% =========================================================
% 【扩展部分四】图3-10：不同滚降系数 \beta 下的BER曲线
% 结论：理想同步+匹配滤波下，BER与\beta基本无关（统计涨落范围内），
%       \beta只折中"带宽"与"实现复杂度/定时敏感度"。
% ==========================================================

EbN0ListBeta = 0:2:10;
BER_beta = zeros(numel(betaList), numel(EbN0ListBeta));
NbitBeta = 120000;
bitsBeta = randi([0 1],1,NbitBeta);

for ib = 1:numel(betaList)
    hb = myRRC(betaList(ib), span, sps);
    for ii = 1:numel(EbN0ListBeta)
        rTemp = runCommunication(bitsBeta, 4, hb, sps, EbN0ListBeta(ii));
        BER_beta(ib,ii) = rTemp.ber;
    end
    fprintf('\beta=%.1f 完成\n', betaList(ib));
end

figure;
semilogy(EbN0ListBeta, BER_beta(1,:), 'o-', 'LineWidth',1.2); hold on;
semilogy(EbN0ListBeta, BER_beta(2,:), 's-', 'LineWidth',1.2);
semilogy(EbN0ListBeta, BER_beta(3,:), '^-', 'LineWidth',1.2);
semilogy(EbN0ListBeta, 0.5*erfc(sqrt(10.^(EbN0ListBeta/10))), '--', 'LineWidth',1.2);
xlabel('E_b/N_0 (dB)'); ylabel('BER');
title('不同滚降系数\beta下的QPSK BER性能');
legend('\beta=0.2','\beta=0.5','\beta=1.0','QPSK理论', 'Location','southwest');
grid on;

fprintf('\n===========================================\n');
fprintf('不同beta的BER (QPSK)\n');
fprintf('Eb/N0(dB)   beta=0.2      beta=0.5      beta=1.0\n');
for ii = 1:numel(EbN0ListBeta)
    fprintf('%5.1f     %10.3e    %10.3e    %10.3e\n', ...
        EbN0ListBeta(ii), BER_beta(1,ii), BER_beta(2,ii), BER_beta(3,ii));
end
fprintf('===========================================\n');


%% =========================================================
% 表格导出：矩形脉冲 vs RRC 的 QPSK BER 对比表
% 【插入位置】"矩形脉冲和RRC在AWGN下的BER比较"一节的末尾，
%   即该节最后一条语句 grid on; 之后、下一节 %% 之前。
% 【注意】不要插到脚本开头！EbN0ListPulse/BERrect/BERrrc/
%   BERtheory 这些变量只在上面那段 for 循环跑完之后才存在。
% ==========================================================

% --- 1) 命令行打印（可直接复制进 Word 表格）---
fprintf('\n===== QPSK BER: Rect vs RRC vs Theory =====\n');
fprintf('%-12s %-18s %-18s %-18s\n', ...
    'Eb/N0 (dB)', 'Rect sim BER', 'RRC sim BER', 'QPSK theory BER');
for ii = 1:length(EbN0ListPulse)
    fprintf('%-12g %-18.3e %-18.3e %-18.3e\n', ...
        EbN0ListPulse(ii), BERrect(ii), BERrrc(ii), BERtheory(ii));
end
