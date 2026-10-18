# 02. Linux LVM 스토리지 확장

## 1. 실습 목적

Ubuntu Server에서 LVM(Logical Volume Manager)을 활용하여 디스크 공간을 확장하고, Linux 서버의 스토리지 관리 구조를 이해한다.

## 2. 실습 환경

| 항목 | 설정 |
|---|---|
| 가상화 플랫폼 | VMware Workstation Pro |
| 운영체제 | Ubuntu Server 24.04 LTS |
| 가상 디스크 | 30GB |
| 스토리지 관리 | LVM |
| 루트 논리 볼륨 | ubuntu-vg/ubuntu-lv |

## 3. LVM 구성 이해

LVM은 물리적인 디스크 공간을 유연하게 관리하기 위한 Linux 스토리지 관리 기술이다.

- PV (Physical Volume): LVM이 사용하는 물리 볼륨
- VG (Volume Group): PV를 묶어 관리하는 볼륨 그룹
- LV (Logical Volume): VG에서 할당받아 사용하는 논리 볼륨

### LVM 구조

```text
VMware Virtual Disk (30GB)
        |
        v
/dev/sda3 (28GB)
        |
        v
PV (Physical Volume)
        |
        v
VG (ubuntu-vg)
        |
        v
LV (ubuntu-lv, 28GB)
        |
        v
Root Filesystem (/)
```

## 4. 실습 내용

### 4.1 디스크 및 LVM 상태 확인

```bash
lsblk
sudo pvs
sudo vgs
sudo lvs
df -h /
```

### 4.2 LVM 확장

실습에서 루트 논리 볼륨과 파일시스템을 약 14GB에서 28GB로 확장하였다.

LVM 논리 볼륨 확장에 사용하는 대표적인 명령어:

```bash
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
```

파일시스템 확장에 사용하는 명령어(예: ext4):

```bash
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```

※ 위 명령어는 LVM 확장 원리를 설명하기 위한 예시이며, 실제 실행 명령어와 파일시스템 종류는 별도 확인이 필요하다.

## 5. 검증 결과

- 가상 디스크 크기: 30GB
- 루트 LVM 크기: 약 14GB → 28GB
- 루트 파일시스템 마운트: `/`
- 확장된 논리 볼륨 인식 확인

## 6. 학습 내용

LVM의 PV, VG, LV 구조를 이해하고 논리 볼륨과 파일시스템의 용량을 확장하는 방법을 학습했다.

디스크 공간 확장 시 논리 볼륨과 파일시스템의 크기를 각각 확인해야 한다는 점을 이해했다.

실제 서버 운영에서는 작업 전 백업 및 복구 계획을 수립하고, 파일시스템 종류와 가용 공간을 확인한 후 확장해야 한다.
