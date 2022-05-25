clear all; clc; close all


gt_LLH = readtable('ground_truth_llh.csv');

gt_ECEF = gt_LLH;

for i = 1:size(gt_LLH,1)
    gt_ECEF{i,2:end} = GeodeticToECEF(gt_LLH{i,2:end});
end



%%

GNSS_msg = readtable('2021-05-17_HK_GNSS_Message_m8t.csv');
GNSS_msg{:,2} = GNSS_msg{:,2}*1e-9;

GNSS_msg.rec_bias = nan(size(GNSS_msg,1),1);
GNSS_msg.GT_x = nan(size(GNSS_msg,1),1);
GNSS_msg.GT_y = nan(size(GNSS_msg,1),1);
GNSS_msg.GT_z = nan(size(GNSS_msg,1),1);
GNSS_msg.cov = ones(size(GNSS_msg,1),1)*-1;

%%

recb = readtable('recb.txt');
recb.epoch = (1:length(recb{:,1}))';

for i = 1:size(GNSS_msg,1)
    epoch = GNSS_msg{i,1};
    GNSS_msg{i,14} = recb{epoch,2};
end

%%

for i = 1:size(GNSS_msg,1)
    [m,idx] = min(abs(GNSS_msg{i,2}-gt_ECEF{:,1}));
    GNSS_msg{i,15:17} = gt_ECEF{idx,2:4};
end

%%

c = 299792458;

residuals1 = [];
residuals4 = [];
for i = 1:size(GNSS_msg,1)
    [m,idx] = min(abs(GNSS_msg{i,2}-gt_ECEF{:,1}));
    gt_pos = gt_ECEF{idx,2:4};
    
    sat_pos = GNSS_msg{i,10:12};
    
    rec_clock_error = GNSS_msg{i,14};
    pr = GNSS_msg{i,4};
    
    res = norm(gt_pos - sat_pos) - pr + c*rec_clock_error;

    if(GNSS_msg{i,13} == 1)
        residuals1 = [residuals1, res ];
    elseif(GNSS_msg{i,13} == 4)
        residuals4 = [residuals4, res ];
    end

    GNSS_msg{i,15:17} = gt_pos;
 
end
hold on
histogram(residuals1,1000)
histogram(residuals4,1000)
xlim([-200,200])
%%
cov_data = readtable('cov.txt');
current_epoch = -1;
for i = 1:size(cov_data,1)
    satId = cov_data{i,1};
    if satId == -1
        epoch_t = cov_data{i,3};
        idx = find(recb{:,1} == epoch_t);
        current_epoch = recb{idx,3};
    else
        GNSS_msg_idx = find(GNSS_msg{:,1} == current_epoch & GNSS_msg{:,3} == satId);
        GNSS_msg{GNSS_msg_idx,'cov'} = cov_data{i,5}^2;
    end
end
%%
GNSS_normalized = GNSS_msg;

for i = 1:size(GNSS_msg,1)
    gt_pos = GNSS_normalized{i,15:17};
    GNSS_normalized{i,10:12} = GNSS_normalized{i,10:12} - gt_pos;

end

GNSS_normalized(:,15:17) = [];
GNSS_normalized(:,7:9) = [];
GNSS_normalized(:,5) = []; 
%%

gt_port = readtable('gt_port.csv');

gt_port_ECEF = gt_port;

for i = 1:size(gt_port,1)
    gt_port_ECEF{i,2:end} = GeodeticToECEF(gt_port{i,2:end});
end

gt_port_ECEF.rel_time = nan(size(gt_port_ECEF,1),1);
gt_port_ECEF{:,'rel_time'} = (gt_port_ECEF{:,1}-gt_port_ECEF{1,1})*1e-9;

GNSS_normalized_rel_time = (GNSS_normalized{:,2}-GNSS_normalized{1,2});
%%

GNSS_augmented = GNSS_normalized;
used_epochs = [];
for i = 1:size(gt_port_ECEF)
    time_diff = abs(gt_port_ECEF{i,'rel_time'}-GNSS_normalized_rel_time);
    [m,idx] = min(time_diff);
    epoch_selected = GNSS_augmented{idx,1};
    if ~ismember(epoch_selected,used_epochs)
        used_epochs = [used_epochs,epoch_selected]
        m
        epoch_idxs = find(GNSS_normalized{:,1} == epoch_selected)

        for j = 1:length(epoch_idxs)
            epoch_idx = epoch_idxs(j);
            GNSS_augmented{epoch_idx,6:8} = GNSS_augmented{epoch_idx,6:8} + gt_port_ECEF{i,2:4};
            GNSS_augmented{epoch_idx,2} = gt_port_ECEF{i,1};
        end

    end
end
GNSS_augmented = GNSS_augmented(find(GNSS_augmented{:,1}<=max(used_epochs)),:);

%%
GNSS_augmented = GNSS_normalized;

for i = 1:size(GNSS_augmented,1)
    time_diff = abs(GNSS_normalized_rel_time(i) - gt_port_ECEF{:,'rel_time'});
    [m,idx] = min(time_diff)
    if m > 1
        break
    end
    GNSS_augmented{i,6:8} = GNSS_augmented{i,6:8} + gt_port_ECEF{idx,2:4};
    GNSS_augmented{i,2} = gt_port_ECEF{idx,1};
    last_epoch = GNSS_augmented{i,1};
end
GNSS_augmented = GNSS_augmented(find(GNSS_augmented{:,1}<=last_epoch),:);
%%

writetable(GNSS_augmented,'gnss_augmented.txt','WriteRowNames',false);