#!/bin/bash
export CUDA_DEVICE_MAX_CONNECTIONS=1
export WANDB_API_KEY="YOUR_API_KEY"
DIR=`pwd`


GPUS_PER_NODE=2
NNODES=1
NODE_RANK=0
MASTER_ADDR=localhost
MASTER_PORT=6001

MODEL="Qwen/Qwen-VL-Chat" #"Qwen/Qwen-VL-Chat"/"Qwen/Qwen-VL"  Set the path if you do not want to load from huggingface directly
# ATTENTION: specify the path to your training data, which should be a json file consisting of a list of conversations.
# See the section for finetuning in README for more information.
DATA="datasets/scienceqa/train_sqa_qwen.json"

DISTRIBUTED_ARGS="
    --nproc_per_node $GPUS_PER_NODE \
    --nnodes $NNODES \
    --node_rank $NODE_RANK \
    --master_addr $MASTER_ADDR \
    --master_port $MASTER_PORT
"

torchrun $DISTRIBUTED_ARGS qwen/finetune_peft.py \
    --model_name_or_path $MODEL \
    --data_path $DATA \
    --bf16 True \
    --output_dir checkpoints/qwen-vl-chat/sqa/qwen-sqa-adapter \
    --num_train_epochs 3 \
    --per_device_train_batch_size 8 \
    --per_device_eval_batch_size 1 \
    --gradient_accumulation_steps 8 \
    --evaluation_strategy "no" \
    --save_strategy "steps" \
    --save_steps 50000 \
    --save_total_limit 1 \
    --learning_rate 5e-5 \
    --weight_decay 0.1 \
    --adam_beta2 0.95 \
    --warmup_ratio 0.01 \
    --lr_scheduler_type "cosine" \
    --logging_steps 1 \
    --report_to wandb \
    --model_max_length 2048 \
    --lazy_preprocess True \
    --gradient_checkpointing \
    --adapter_enable --bottleneck_size 256 \
    --deepspeed scripts/qwen/ds_config_zero2.json &&

torchrun $DISTRIBUTED_ARGS qwen/finetune_peft.py \
    --model_name_or_path $MODEL \
    --data_path $DATA \
    --bf16 True \
    --output_dir checkpoints/qwen-vl-chat/sqa/qwen-sqa-lora \
    --num_train_epochs 3 \
    --per_device_train_batch_size 8 \
    --per_device_eval_batch_size 1 \
    --gradient_accumulation_steps 8 \
    --evaluation_strategy "no" \
    --save_strategy "steps" \
    --save_steps 50000 \
    --save_total_limit 1 \
    --learning_rate 2e-4 \
    --weight_decay 0.1 \
    --adam_beta2 0.95 \
    --warmup_ratio 0.01 \
    --lr_scheduler_type "cosine" \
    --logging_steps 1 \
    --report_to wandb \
    --model_max_length 2048 \
    --lazy_preprocess True \
    --gradient_checkpointing \
    --lora_enable --lora_r 128 --lora_alpha 256 \
    --deepspeed scripts/qwen/ds_config_zero2.json &&

torchrun $DISTRIBUTED_ARGS qwen/finetune_peft.py \
    --model_name_or_path $MODEL \
    --data_path $DATA \
    --bf16 True \
    --output_dir checkpoints/qwen/sqa/qwen-sqa-ia3 \
    --num_train_epochs 3 \
    --per_device_train_batch_size 8 \
    --per_device_eval_batch_size 1 \
    --gradient_accumulation_steps 8 \
    --evaluation_strategy "no" \
    --save_strategy "steps" \
    --save_steps 50000 \
    --save_total_limit 1 \
    --learning_rate 2e-4 \
    --weight_decay 0.1 \
    --adam_beta2 0.95 \
    --warmup_ratio 0.01 \
    --lr_scheduler_type "cosine" \
    --logging_steps 1 \
    --report_to wandb \
    --model_max_length 2048 \
    --lazy_preprocess True \
    --gradient_checkpointing \
    --ia3_enable \
    --deepspeed scripts/qwen/ds_config_zero2.json
