/*
 * AES-128 CTR Mode - MPI Parallel Implementation
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <mpi.h>

// --- CONSTANTES ---
static const uint8_t AES_KEY[16] = {0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c};
static const uint8_t AES_IV[16]  = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f};
static const uint8_t sbox[256] = {
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
};
static const uint8_t Rcon[11] = {0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36};

#define Nb 4
#define Nk 4
#define Nr 10

// --- FUNCIONES AES CORE ---
static void SubBytes(uint8_t *state) { for (int i=0; i<16; i++) state[i] = sbox[state[i]]; }
static void ShiftRows(uint8_t *state) {
    uint8_t t;
    t=state[1]; state[1]=state[5]; state[5]=state[9]; state[9]=state[13]; state[13]=t;
    t=state[2]; state[2]=state[10]; state[10]=t; t=state[6]; state[6]=state[14]; state[14]=t;
    t=state[15]; state[15]=state[11]; state[11]=state[7]; state[7]=state[3]; state[3]=t;
}
static uint8_t xtime(uint8_t x) { return ((x<<1) ^ (((x>>7)&1)*0x1b)); }
static void MixColumns(uint8_t *state) {
    uint8_t tmp, tm, t;
    for(int i=0; i<4; i++) {
        t=state[i*4];
        tmp = state[i*4] ^ state[i*4+1] ^ state[i*4+2] ^ state[i*4+3];
        tm = state[i*4] ^ state[i*4+1]; tm = xtime(tm); state[i*4] ^= tm ^ tmp;
        tm = state[i*4+1] ^ state[i*4+2]; tm = xtime(tm); state[i*4+1] ^= tm ^ tmp;
        tm = state[i*4+2] ^ state[i*4+3]; tm = xtime(tm); state[i*4+2] ^= tm ^ tmp;
        tm = state[i*4+3] ^ t; tm = xtime(tm); state[i*4+3] ^= tm ^ tmp;
    }
}
static void AddRoundKey(uint8_t round, uint8_t *state, uint8_t *RoundKey) {
    for(int i=0; i<16; i++) state[i] ^= RoundKey[round*Nb*4+i];
}
void AES_KeyExpansion(const uint8_t *Key, uint8_t *RoundKey) {
    int i, j, k; uint8_t tempa[4];
    for(i=0; i<Nk; i++) {
        RoundKey[i*4]=Key[i*4]; RoundKey[i*4+1]=Key[i*4+1];
        RoundKey[i*4+2]=Key[i*4+2]; RoundKey[i*4+3]=Key[i*4+3];
    }
    for(i=Nk; i<Nb*(Nr+1); i++) {
        k=(i-1)*4; tempa[0]=RoundKey[k]; tempa[1]=RoundKey[k+1]; tempa[2]=RoundKey[k+2]; tempa[3]=RoundKey[k+3];
        if(i%Nk==0) {
            k=tempa[0]; tempa[0]=tempa[1]; tempa[1]=tempa[2]; tempa[2]=tempa[3]; tempa[3]=k;
            tempa[0]=sbox[tempa[0]]; tempa[1]=sbox[tempa[1]]; tempa[2]=sbox[tempa[2]]; tempa[3]=sbox[tempa[3]];
            tempa[0] = tempa[0] ^ Rcon[i/Nk];
        }
        j=i*4; k=(i-Nk)*4;
        RoundKey[j]=RoundKey[k]^tempa[0]; RoundKey[j+1]=RoundKey[k+1]^tempa[1];
        RoundKey[j+2]=RoundKey[k+2]^tempa[2]; RoundKey[j+3]=RoundKey[k+3]^tempa[3];
    }
}
void AES_Cipher(uint8_t *state, uint8_t *RoundKey) {
    uint8_t round=0; AddRoundKey(0, state, RoundKey);
    for(round=1; round<Nr; round++) { SubBytes(state); ShiftRows(state); MixColumns(state); AddRoundKey(round, state, RoundKey); }
    SubBytes(state); ShiftRows(state); AddRoundKey(Nr, state, RoundKey);
}

// --- CTR LOGIC & OFFSET ---
void increment_counter(uint8_t *counter) {
    for (int i = 15; i >= 0; i--) { if (++counter[i] != 0) break; }
}
void set_counter_offset(uint8_t *counter, const uint8_t *iv, uint64_t offset) {
    memcpy(counter, iv, 16);
    uint64_t block_offset = offset / 16;
    for (int i = 15; i >= 8 && block_offset > 0; i--) {
        uint64_t sum = counter[i] + (block_offset & 0xFF);
        counter[i] = sum & 0xFF;
        block_offset = (block_offset >> 8) + (sum >> 8);
    }
}

// --- MAIN MPI ---
int main(int argc, char *argv[]) {
    int rank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc != 3 && rank == 0) {
        fprintf(stderr, "Uso: mpirun -n <np> %s <input> <output>\n", argv[0]);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    uint8_t *full_data = NULL;
    uint8_t *local_data = NULL;
    uint8_t *enc_data = NULL;
    long file_size = 0;
    int chunk_size = 0;
    double start_t, end_t;

    if (rank == 0) {
        FILE *f = fopen(argv[1], "rb");
        if (!f) { perror("Error archivo"); MPI_Abort(MPI_COMM_WORLD, 1); }
        fseek(f, 0, SEEK_END); file_size = ftell(f); rewind(f);

        // Padding para dividir exacto
        int align = 16 * size;
        int rem = file_size % align;
        int pad = (rem == 0) ? 0 : align - rem;
        long padded_size = file_size + pad;
        chunk_size = padded_size / size;

        full_data = calloc(padded_size, 1);
        if (fread(full_data, 1, file_size, f) != file_size) {}
        fclose(f);
        
        enc_data = malloc(padded_size);
    }

    MPI_Bcast(&chunk_size, 1, MPI_INT, 0, MPI_COMM_WORLD);
    local_data = malloc(chunk_size);

    MPI_Barrier(MPI_COMM_WORLD);
    start_t = MPI_Wtime(); // INICIO CRONÓMETRO

    MPI_Scatter(full_data, chunk_size, MPI_BYTE, local_data, chunk_size, MPI_BYTE, 0, MPI_COMM_WORLD);

    uint8_t RoundKey[176], counter[16], kstream[16];
    AES_KeyExpansion(AES_KEY, RoundKey);
    
    // Offset local
    set_counter_offset(counter, AES_IV, (uint64_t)rank * chunk_size);

    for (int i = 0; i < chunk_size; i += 16) {
        memcpy(kstream, counter, 16);
        AES_Cipher(kstream, RoundKey);
        for (int j = 0; j < 16; j++) local_data[i+j] ^= kstream[j];
        increment_counter(counter);
    }

    MPI_Gather(local_data, chunk_size, MPI_BYTE, enc_data, chunk_size, MPI_BYTE, 0, MPI_COMM_WORLD);

    end_t = MPI_Wtime(); // FIN CRONÓMETRO

    if (rank == 0) {
        FILE *f = fopen(argv[2], "wb");
        fwrite(enc_data, 1, file_size, f); // Escribir solo tamaño real (sin padding)
        fclose(f);
        free(full_data); free(enc_data);
        // FORMATO CLAVE PARA PYTHON
        printf("completado en %f segundos\n", end_t - start_t);
    }

    free(local_data);
    MPI_Finalize();
    return 0;
}