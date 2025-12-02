#!/usr/bin/env python3
"""
实时情绪预测测试脚本
- 缓存10秒内的输入
- 最多保留20个字
- 实时预测情绪并显示对应emoji
"""

import torch
import json
import time
import threading
import sys
from collections import deque
from transformers import BertTokenizer, BertForSequenceClassification

# 配置
MODEL_PATH = "./output/emoji_model"
EMOJI_MAP_PATH = "./output/emoji_map.json"
MAX_CHARS = 20  # 最大缓存字数
CACHE_TIMEOUT = 10  # 缓存超时时间（秒）
PREDICTION_INTERVAL = 0.5  # 预测间隔（秒）


class RealtimeEmotionPredictor:
    def __init__(self):
        print("加载模型中...")
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        print(f"使用设备: {self.device}")
        
        # 加载模型和tokenizer
        self.tokenizer = BertTokenizer.from_pretrained(MODEL_PATH)
        self.model = BertForSequenceClassification.from_pretrained(MODEL_PATH)
        self.model.to(self.device)
        self.model.eval()
        
        # 加载emoji映射 (格式: {"0": "😂", "1": "😄", ...})
        with open(EMOJI_MAP_PATH, 'r', encoding='utf-8') as f:
            self.emoji_map = json.load(f)
        # id_to_emoji: {0: "😂", 1: "😄", ...}
        self.id_to_emoji = {int(k): v for k, v in self.emoji_map.items()}
        
        # 输入缓存：存储 (字符, 时间戳) 元组
        self.char_buffer = deque()
        self.lock = threading.Lock()
        
        # 控制标志
        self.running = True
        self.last_prediction = ""
        self.last_text = ""
        
        print(f"模型加载完成！支持的emoji: {list(self.emoji_map.keys())}")
        print(f"缓存设置: 最多{MAX_CHARS}字, {CACHE_TIMEOUT}秒超时")
        print("-" * 50)
    
    def add_text(self, text):
        """添加文本到缓存"""
        current_time = time.time()
        with self.lock:
            for char in text:
                if char.strip():  # 忽略空白字符
                    self.char_buffer.append((char, current_time))
            
            # 限制最大字数
            while len(self.char_buffer) > MAX_CHARS:
                self.char_buffer.popleft()
    
    def get_cached_text(self):
        """获取有效缓存文本（清除超时字符）"""
        current_time = time.time()
        with self.lock:
            # 移除超时的字符
            while self.char_buffer and (current_time - self.char_buffer[0][1]) > CACHE_TIMEOUT:
                self.char_buffer.popleft()
            
            # 组合成文本
            return ''.join(char for char, _ in self.char_buffer)
    
    def predict(self, text):
        """预测情绪"""
        if not text or len(text) < 2:
            return None, 0.0
        
        with torch.no_grad():
            inputs = self.tokenizer(
                text,
                max_length=128,
                padding='max_length',
                truncation=True,
                return_tensors='pt'
            )
            inputs = {k: v.to(self.device) for k, v in inputs.items()}
            
            outputs = self.model(**inputs)
            probs = torch.softmax(outputs.logits, dim=-1)
            pred_id = torch.argmax(probs, dim=-1).item()
            confidence = probs[0][pred_id].item()
            
            emoji = self.id_to_emoji.get(pred_id, "❓")
            return emoji, confidence
    
    def prediction_loop(self):
        """后台预测循环"""
        while self.running:
            text = self.get_cached_text()
            
            if text and text != self.last_text:
                emoji, confidence = self.predict(text)
                if emoji:
                    self.last_prediction = f"{emoji} ({confidence*100:.1f}%)"
                    self.last_text = text
                    # 清屏并显示当前状态
                    self.display_status(text)
            
            time.sleep(PREDICTION_INTERVAL)
    
    def display_status(self, text):
        """显示当前状态"""
        # 计算缓存剩余时间
        with self.lock:
            if self.char_buffer:
                oldest_time = self.char_buffer[0][1]
                remaining = max(0, CACHE_TIMEOUT - (time.time() - oldest_time))
            else:
                remaining = 0
        
        print(f"\r\033[K", end="")  # 清除当前行
        print(f"📝 缓存[{len(text)}/{MAX_CHARS}字 | {remaining:.1f}s]: {text}")
        print(f"🎭 预测: {self.last_prediction}")
        print(f"\n请输入文字 (输入 'quit' 退出): ", end="", flush=True)
    
    def run(self):
        """运行交互式测试"""
        print("\n" + "=" * 50)
        print("🎤 实时情绪预测测试")
        print("=" * 50)
        print("使用说明:")
        print("  - 输入文字后按回车，文字会被添加到缓存")
        print("  - 系统会实时分析缓存中的文字并预测情绪")
        print("  - 超过10秒的文字会自动清除")
        print("  - 最多保留20个字")
        print("  - 输入 'quit' 或 'q' 退出")
        print("  - 输入 'clear' 或 'c' 清空缓存")
        print("=" * 50 + "\n")
        
        # 启动后台预测线程
        prediction_thread = threading.Thread(target=self.prediction_loop, daemon=True)
        prediction_thread.start()
        
        print("请输入文字 (输入 'quit' 退出): ", end="", flush=True)
        
        try:
            while self.running:
                try:
                    user_input = input()
                    
                    if user_input.lower() in ['quit', 'q', 'exit']:
                        print("\n👋 再见！")
                        self.running = False
                        break
                    elif user_input.lower() in ['clear', 'c']:
                        with self.lock:
                            self.char_buffer.clear()
                        self.last_text = ""
                        self.last_prediction = ""
                        print("🗑️ 缓存已清空")
                        print("请输入文字 (输入 'quit' 退出): ", end="", flush=True)
                    elif user_input.strip():
                        self.add_text(user_input)
                        # 立即触发一次预测
                        text = self.get_cached_text()
                        if text:
                            emoji, confidence = self.predict(text)
                            if emoji:
                                self.last_prediction = f"{emoji} ({confidence*100:.1f}%)"
                                self.last_text = text
                                self.display_status(text)
                    else:
                        print("请输入文字 (输入 'quit' 退出): ", end="", flush=True)
                        
                except EOFError:
                    break
                    
        except KeyboardInterrupt:
            print("\n\n👋 再见！")
            self.running = False


def main():
    predictor = RealtimeEmotionPredictor()
    predictor.run()


if __name__ == "__main__":
    main()
