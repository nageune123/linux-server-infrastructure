# 09. Linux Server Incident Response

## 1. 실습 개요

VMware Workstation Pro의 Ubuntu Server 환경에서 SSH 서비스 장애, 디스크 사용량 증가, CPU 과부하 상황을 재현하고 원인을 분석하여 복구하는 실습을 진행했습니다.

단순한 명령어 실행이 아니라 **장애 발생 → 원인 분석 → 복구 → 정상 상태 검증** 순서로 서버 운영 및 장애 대응 과정을 학습했습니다.

## 2. 실습 환경

| 항목 | 환경 |
|---|---|
| 가상화 | VMware Workstation Pro |
| 운영체제 | Ubuntu Server 24.04 LTS |
| CPU | 2 vCPU |
| 메모리 | 3GB |
| 디스크 | 30GB 가상 디스크, 루트 파일시스템 약 28GB |
| 서버 IP | 192.168.109.128 (Host-only) |
| 관리자 계정 | admin1 |

## 3. SSH 서비스 장애 대응

### 장애 상황

SSH 서비스가 중지되어 원격 접속에 문제가 발생하는 상황을 가정했습니다.

### 장애 재현 및 진단

VMware 콘솔에서 SSH 서비스를 중지하고 상태와 로그를 확인했습니다.

```bash
sudo systemctl status ssh --no-pager
sudo systemctl stop ssh
sudo systemctl status ssh --no-pager
sudo journalctl -u ssh -n 20 --no-pager
sudo ss -tlnp | grep ':22 '
```

### 장애 복구

```bash
sudo systemctl start ssh
sudo systemctl status ssh --no-pager
```

Windows PowerShell에서 SSH 재접속을 검증했습니다.

```powershell
ssh -4 admin1@192.168.109.128
```

**결과:** SSH 서비스 복구 및 원격 접속 정상화.

Ubuntu 24.04의 SSH 소켓 활성화 환경에서는 서비스 중지와 실제 접속 차단이 반드시 일치하지 않을 수 있으므로 서비스 상태 및 로그를 중심으로 확인했습니다.

## 4. 디스크 사용량 증가 대응

### 장애 상황

디스크 사용량이 증가한 상황을 테스트 파일로 재현하고, 사용량 증가 원인을 찾아 복구했습니다.

### 장애 전 상태

```bash
df -h /
sudo du -sh /var/log /tmp
```

확인 결과 루트 파일시스템은 약 28GB이며, 초기 사용량은 약 5.9GB, 사용률은 23%였습니다.

### 장애 재현

```bash
mkdir -p /tmp/disk-test
fallocate -l 1G /tmp/disk-test/testfile.img
```

### 원인 분석

```bash
df -h /
du -sh /tmp/disk-test
ls -lh /tmp/disk-test/
```

### 복구

```bash
rm /tmp/disk-test/testfile.img
rmdir /tmp/disk-test
df -h /
```

**결과:** 실습용 1GB 파일을 제거하여 사용량 증가 원인을 정리했습니다.

이 실습은 실제 디스크 고갈이 아닌 안전한 디스크 사용량 증가 재현입니다.

## 5. CPU 과부하 장애 대응

### 장애 상황

CPU를 과도하게 사용하는 프로세스를 생성하고, 원인 프로세스를 찾아 종료했습니다.

### 장애 재현

```bash
yes > /dev/null &
```

### 원인 분석

```bash
top
ps -eo pid,comm,%cpu --sort=-%cpu | head -10
jobs -l
```

CPU 사용률이 높은 `yes` 프로세스를 확인했습니다.

- 문제 프로세스: yes
- PID: 3698
- 확인된 CPU 사용률: 100%

### 장애 복구

```bash
kill 3698
ps -eo pid,comm,%cpu --sort=-%cpu | head -10
jobs -l
```

`yes` 프로세스가 목록에서 사라지고 `Terminated` 상태로 표시되는 것을 확인했습니다.

**결과:** CPU 부하 원인 프로세스 종료 및 복구 확인.


## 6. 실습을 통해 배운 점

- `systemctl`, `journalctl`을 이용한 서비스 장애 분석
- `df`, `du`를 활용한 디스크 사용량 및 원인 분석
- `top`, `ps`를 활용한 CPU 과부하 프로세스 탐색
- `kill`을 이용한 원인 프로세스 종료
- 장애 발생 전후 상태 비교와 복구 검증
- 시스템 장애 시 서비스와 프로세스를 무조건 종료하기보다 원인을 먼저 확인하는 절차의 중요성

## 7. 최종 결과

| 장애 시나리오 | 대응 결과 |
|---|---|
| SSH 서비스 장애 | 서비스 복구 및 SSH 접속 확인 |
| 디스크 사용량 증가 | 원인 파일 확인 및 삭제 |
| CPU 과부하 | 문제 프로세스 확인 및 종료 |

**최종적으로 세 가지 장애 시나리오에 대한 진단과 복구 실습을 완료했습니다.**
