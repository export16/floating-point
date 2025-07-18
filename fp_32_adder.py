import struct
import random
import numpy as np

flag = 0

def generate_random_fp32_pair():
        
    while True:
        # 生成第一个数
        bits1 = random.getrandbits(32)
        sign1 = random.choice([0, 1])
        exp1 = random.randint(0, 254)  # 正常数范围
        mantissa1 = random.getrandbits(23)
        bits1 = (sign1 << 31) | (exp1 << 23) | mantissa1
        
        # 生成第二个数，确保指数差不超过max_exp_diff
        exp2 = random.randint(0, 254)
        # if exp2 < 1 or exp2 > 254:  # 确保仍然是正常数
            # continue
            
        sign2 = random.choice([0, 1]) 
        mantissa2 = random.getrandbits(23)
        bits2 = (sign2 << 31) | (exp2 << 23) | mantissa2
        
        return bits1, bits2

def main():

    # while 1:
        # 生成两个随机FP32数
        for i in range(1, 2000):
            a_bits,  b_bits = generate_random_fp32_pair()
            
            # with open('numbers.txt', 'a') as f:
            #     f.write(f"{a_bits:032b}\n")
            #     f.write(f"{b_bits:032b}\n")
            #     f.write(f"{simulated_bits:032b}\n")
            
            # 直接加法
            a = struct.unpack('!f', struct.pack('!I', a_bits))[0]
            b = struct.unpack('!f', struct.pack('!I', b_bits))[0]
            direct_sum = np.float32(a) + np.float32(b)
            direct_bits = struct.unpack('!I', struct.pack('!f', direct_sum))[0]
            
            
            if np.isnan(struct.unpack('!f', struct.pack('!I', direct_bits))[0]) != True:
                with open('fp_test_data.txt', 'a') as f:
                    f.write(f"{a_bits:032b}\n")
                    f.write(f"{b_bits:032b}\n")
                    f.write(f"{direct_bits:032b}\n")

if __name__ == "__main__":
    main()