import struct
import random
import numpy as np

flag = 0

def generate_random_fp8_pair():
        
    while True:
        # 生成第一个数
        bits1 = random.getrandbits(8)
        sign1 = random.choice([0, 1])
        exp1 = random.randint(0, 31)  # 正常数范围
        mantissa1 = random.getrandbits(2)
        bits1 = (sign1 << 7) | (exp1 << 2) | mantissa1
        
        # 生成第二个数，确保指数差不超过max_exp_diff
        exp2 = random.randint(0, 31)
        # if exp2 < 1 or exp2 > 254:  # 确保仍然是正常数
            # continue
            
        sign2 = random.choice([0, 1]) 
        mantissa2 = random.getrandbits(2)
        bits2 = (sign2 << 7) | (exp2 << 2) | mantissa2
        
        return bits1, bits2

def main():
    with open('fp_test_data.txt', 'w') as f:

    # while 1:
        # 生成两个随机FP32数
        for i in range(1, 2000):
            a_bits,  b_bits = generate_random_fp8_pair()
            
            # with open('numbers.txt', 'a') as f:
            #     f.write(f"{a_bits:032b}\n")
            #     f.write(f"{b_bits:032b}\n")
            #     f.write(f"{simulated_bits:032b}\n")

            
            sign = (a_bits >> 7)
            exp = (a_bits >> 2) % 32 + 112
            mantissa = (a_bits % (1 << 2)) << 21 
            if (a_bits >> 2) % 32 == 0:
                if (a_bits % (1 << 2)) == 0:
                    exp = 0
                else:
                    while mantissa < (1 << 23):
                        exp = exp - 1
                        mantissa = (mantissa << 1)
                    exp = exp + 1
                    mantissa = mantissa - (1 << 23)
            a_bit_l = (sign << 31) + (exp << 23) + mantissa
            direct_bits = 0

            if (a_bits >> 2) % 32 == 31:
                if (a_bits % (1 << 2)) == 0:
                    if (b_bits >> 2) % 32 == 31 and (b_bits % (1 << 2)) == 0 and (a_bits >> 7) != (b_bits >> 7):
                        direct_bits = (((a_bits >> 7) ^ (b_bits >> 7)) << 31) + (1 << 31) - 1
                    elif (b_bits >> 2) % 32 == 31 and (b_bits % (1 << 2)) != 0:
                        direct_bits = (((a_bits >> 7) ^ (b_bits >> 7)) << 31) + (1 << 31) - 1
                    else:
                        direct_bits = (((a_bits >> 7) ^ (b_bits >> 7)) << 31) + (((1 << 8) - 1) << 23)
                else:
                    direct_bits = (((a_bits >> 7) ^ (b_bits >> 7)) << 31) + (1 << 31) - 1
            
            elif (b_bits >> 2) % 32 == 31:
                if (b_bits % (1 << 2)) == 0:
                    direct_bits = (((a_bits >> 7) ^ (b_bits >> 7)) << 31) + (((1 << 8) - 1) << 23)
                else:
                    direct_bits = (((a_bits >> 7) ^ (b_bits >> 7)) << 31) + (1 << 31) - 1
            
            else:
                sign = (b_bits >> 7)
                exp = (b_bits >> 2) % 32 + 112
                mantissa = (b_bits % (1 << 2)) << 21
                if (b_bits >> 2) % 32 == 0:
                    if (b_bits % (1 << 2)) == 0:
                        exp = 0
                    else:
                        while mantissa < (1 << 23):
                            exp = exp - 1
                            mantissa = (mantissa << 1)
                        exp = exp + 1
                        mantissa = mantissa - (1 << 23)
                b_bit_l = (sign << 31) + (exp << 23) + mantissa

                # 直接加法
                a = struct.unpack('!f', struct.pack('!I', a_bit_l))[0]
                b = struct.unpack('!f', struct.pack('!I', b_bit_l))[0]
                direct_sum = np.float32(a) * np.float32(b)
                direct_bits = struct.unpack('!I', struct.pack('!f', direct_sum))[0]
            
            
            if np.isnan(struct.unpack('!f', struct.pack('!I', direct_bits))[0]) != True:
                with open('fp_test_data.txt', 'a') as f:
                    f.write(f"{a_bits:08b}\n")
                    f.write(f"{b_bits:08b}\n")
                    f.write(f"{direct_bits:032b}\n")

if __name__ == "__main__":
    main()