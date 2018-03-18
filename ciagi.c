#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

uint8_t P[256];
uint8_t O[256]; // 256 times db
int8_t input_value = 0;
int8_t valid = 0;
int8_t first_permutation = 1;
int8_t numbers_in_first_set = 0;
int8_t numbers_in_current_set = 0;
int8_t c;
int8_t working = 1;
int file_desc;

void exit_ok() {
    printf("\n !!! OK !!! \n");
    exit(0);
}

void exit_not_ok() {
    printf("\n current: %d, first: %d, value: %d, valid: %d", numbers_in_current_set, numbers_in_first_set, input_value, valid);
    printf("\n !!! NOT OK !!! \n");
    exit(1);
}

void check_if_is_valid_and_exit() {
    printf("\ncheck");
    if (first_permutation == 1 || valid == 1) {
        exit_ok();
    }
    exit_not_ok();
}

void check_if_argc_equals_2(int argc) {
    if (argc != 2) {
        exit_not_ok();
    }
}

void check_if_filename_is_correct(char* argv[]) {
    file_desc = open(argv[1], O_RDONLY);

    if (file_desc < 0) {
        exit_not_ok();
    }
}

void read_char_from_file() {
    if (read(file_desc, &c, 1) < 0) {
        working = 0;
    }
}

int main(int argc, char* argv[]) {
    check_if_argc_equals_2(argc);
    check_if_filename_is_correct(argv);

// main_loop:
    while(working) {
        read_char_from_file();
        if (c != ' ') {
// handle_digit:
            if (c >= '0' && c <= '9') {
                input_value += input_value*10 + (c - '0');
                continue; // jump_to_main_loop;
            }
            if (c == 10) {
                break;
            }
            printf("FIRST %d\n", c);
            exit_not_ok();
        }

        printf("%d\n", input_value);

        if (input_value == 0) {
            first_permutation = 0;
            printf("current %d\n", numbers_in_current_set);
            if (numbers_in_current_set == 0) {
                first_permutation = 0;
                numbers_in_current_set = numbers_in_first_set;
                for (int i = 0; i < 255; i++) {
                    P[i] = O[i];
                }
                valid = 1;
                continue;
            }

            printf("SECND\n");
            exit_not_ok();
        }

        if (first_permutation) {
            if (O[input_value] == 1) {
                printf("THIRD\n");
                exit_not_ok();
            }

            valid = 1;
            O[input_value] += 1;
            numbers_in_first_set += 1;

            input_value = 0;
            continue;
        }

        if (!first_permutation) {
            if (P[input_value] == 0) {
                printf("4th\n");
                exit_not_ok();
            }
            numbers_in_current_set -= 1;
            P[input_value] -= 1;

            if (numbers_in_current_set == 0) {
                valid = 1;
            }

            input_value = 0;
            continue;
        }
    }

    check_if_is_valid_and_exit();
}
