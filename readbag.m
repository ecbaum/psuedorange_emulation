clear all; clc

bag = rosbag('UrbanNav_HK_Light2_preprocessed.bag');

Topics = bag.AvailableTopics;
%%
temp0_ = select(bag,'Topic','/gnss_preprocessor_node/gnss_raw');

mTemp0_ = readMessages(temp0_);

