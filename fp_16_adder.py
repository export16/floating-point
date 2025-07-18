import struct
import random
import numpy as np

flag = 0

def generate_random_fp16_pair():
        
    while True:
        # 生成第一个数
        bits1 = random.getrandbits(16)
        sign1 = random.choice([0, 1])
        exp1 = random.randint(0, 31)  # 正常数范围
        mantissa1 = random.getrandbits(10)
        bits1 = (sign1 << 15) | (exp1 << 10) | mantissa1
        
        # 生成第二个数，确保指数差不超过max_exp_diff
        exp2 = random.randint(0, 31)
        # if exp2 < 1 or exp2 > 254:  # 确保仍然是正常数
            # continue
            
        sign2 = random.choice([0, 1]) 
        mantissa2 = random.getrandbits(10)
        bits2 = (sign2 << 15) | (exp2 << 10) | mantissa2
        
        return bits1, bits2

def main():

    # while 1:
        # 生成两个随机FP32数
        for i in range(1, 2000):
            a_bits,  b_bits = generate_random_fp16_pair()
            
            # with open('numbers.txt', 'a') as f:
            #     f.write(f"{a_bits:032b}\n")
            #     f.write(f"{b_bits:032b}\n")
            #     f.write(f"{simulated_bits:032b}\n")
            
            # 直接加法

            sign = (a_bits >> 15)
            exp = (a_bits >> 10) % 32 + 112
            mantissa = (a_bits % (1 << 10)) << 13
            a_bit_l = (sign << 31) + (exp << 23) + mantissa
            sign = (b_bits >> 15)
            exp = (b_bits >> 10) % 32 + 112
            mantissa = (b_bits % (1 << 10)) << 13
            b_bit_l = (sign << 31) + (exp << 23) + mantissa
            a = struct.unpack('!f', struct.pack('!I', a_bit_l))[0]
            b = struct.unpack('!f', struct.pack('!I', b_bit_l))[0]
            direct_sum = np.float32(a) + np.float32(b)            
            direct_bits = struct.unpack('!I', struct.pack('!f', direct_sum))[0]
            
            if np.isnan(struct.unpack('!f', struct.pack('!I', direct_bits))[0]) != True:
                with open('fp_test_data.txt', 'a') as f:
                    f.write(f"{a_bits:016b}\n")
                    f.write(f"{b_bits:016b}\n")
                    f.write(f"{direct_bits:032b}\n")

if __name__ == "__main__":
    main()