# 11. Suricata IDS 기반 네트워크 침입 탐지 실습

## 1. 실습 개요

VMware Workstation Pro 환경에서 Ubuntu Server와 Ubuntu Client를 구성하고, Suricata IDS를 이용하여 네트워크 트래픽을 탐지하고 분석하는 실습을 진행하였다.

ICMP Ping 및 SSH 접속 탐지 규칙을 직접 작성하고, 반복적인 SSH 연결 시도를 탐지하여 로그를 분석하였다.

## 2. 실습 환경

| 항목 | 구성 |
|---|---|
| 가상화 환경 | VMware Workstation Pro |
| 운영체제 | Ubuntu Server 24.04 / Ubuntu Client |
| IDS | Suricata 7.0.3 |
| 서버 IP | 192.168.109.128 |
| 클라이언트 IP | 192.168.109.129 |
| 네트워크 | Host-only |
| 탐지 인터페이스 | ens33 |
| 로그 분석 도구 | jq |

## 3. Suricata IDS 동작 원리

Suricata는 네트워크 패킷을 분석하여 미리 정의된 탐지 규칙과 일치하는 트래픽이 발생하면 경고를 생성하는 오픈소스 IDS/IPS이다.

이번 실습에서는 IDS 방식으로 운영하여 의심스러운 트래픽을 탐지하고 로그를 기록하도록 구성하였다.

**탐지 흐름**

Ubuntu Client → 네트워크 트래픽 → Ubuntu Server (Suricata) → 탐지 규칙 검사 → 경고 로그 생성

## 4. ICMP Ping 탐지 실습

ICMP Echo Request 패킷을 탐지하기 위한 규칙을 작성하였다.

```text
alert icmp any any -> any any (msg:"ICMP Ping Detected"; itype:8; sid:1000001; rev:1;)
```

Ubuntu Client에서 다음 명령어로 Ping 패킷을 발생시켰다.

```bash
ping -c 4 192.168.109.128
```

Suricata 로그 확인:

```bash
sudo tail -n 20 /var/log/suricata/fast.log
```

**실습 결과:** ICMP Ping Detected 경고가 기록되었으며, ICMP 패킷 탐지가 정상적으로 동작함을 확인하였다.

## 5. SSH 연결 탐지 실습

서버의 TCP 22번 포트로 들어오는 SSH 연결 시도를 탐지하는 규칙을 작성하였다.

최종적으로 반복 SSH SYN 패킷 탐지를 위한 규칙을 구성하였다.

```text
alert tcp any any -> 192.168.109.128 22 (msg:"Repeated SSH SYN Attempts Detected"; flow:to_server; flags:S; threshold:type threshold, track by_src, count 5, seconds 60; sid:1000002; rev:4;)
```

주요 설정:

- `flags:S`: TCP SYN 패킷 탐지
- `flow:to_server`: 서버 방향 트래픽
- `count 5`: 탐지 기준 패킷 수
- `seconds 60`: 60초 기준
- `sid:1000002`: 규칙 식별 번호

Ubuntu Client에서 SSH 연결 시도를 반복하여 탐지 여부를 확인하였다.

**실습 결과:** `Repeated SSH SYN Attempts Detected` 경고가 발생하였으며, Suricata가 반복 SSH SYN 패킷을 탐지하는 것을 확인하였다.

해당 경고는 반복 연결 패킷 탐지 결과이며, 실제 비밀번호 대입 공격이나 침입 성공을 의미하지는 않는다.

## 6. 탐지 로그 분석

### fast.log

```bash
sudo tail -n 20 /var/log/suricata/fast.log
```

탐지 시간, 출발지 IP, 목적지 IP, 목적지 포트 및 탐지 규칙을 확인하였다.

### eve.json

```bash
sudo jq -c 'select(.alert.signature_id == 1000002) | {timestamp, src_ip, dest_ip, dest_port, signature: .alert.signature, action: .alert.action}' /var/log/suricata/eve.json | tail -n 3
```

JSON 로그를 분석하여 다음 정보를 추출하였다.

- 출발지 IP: 192.168.109.129
- 목적지 IP: 192.168.109.128
- 목적지 포트: TCP 22
- 탐지 규칙: Repeated SSH SYN Attempts Detected
- 탐지 결과: allowed (경고 기록, 차단하지 않음)

## 7. 문제 해결 과정

### 문제 1. SSH 접속 시간 초과

**증상:** Ubuntu Client에서 SSH 접속을 시도했으나 Connection timed out 발생

**원인:** UFW 방화벽에서 클라이언트 IP의 SSH 접근이 허용되지 않음

**해결:** 방화벽 규칙을 점검하고 실습용 클라이언트의 SSH 접근을 허용하여 정상 접속 확인

### 문제 2. SSH 탐지 로그가 발생하지 않음

**증상:** SSH 연결 시도 이후에도 새로운 경고 로그가 기록되지 않음

**확인 과정:**

1. Suricata 서비스 실행 상태 확인
2. 탐지 규칙 및 설정 파일 확인
3. 서버 네트워크 인터페이스 확인
4. 클라이언트와 서버의 실행 환경 확인

**원인:** 클라이언트에서 서버로 SSH 접속한 상태에서 테스트 명령을 실행하여 의도한 신규 연결 트래픽을 발생시키지 못함

**해결:** Ubuntu Client의 로컬 터미널에서 SSH 연결 테스트를 다시 수행하여 탐지 로그 생성 확인

## 8. 실습 결과 및 배운 점

이번 실습을 통해 다음 내용을 학습하였다.

- Suricata IDS 설치 및 서비스 관리
- ICMP 및 TCP 패킷 탐지 규칙 작성
- TCP SYN 패킷과 SSH 연결 과정 이해
- 반복 연결 시도 탐지 및 임계값 설정
- fast.log 및 eve.json 분석
- jq를 활용한 JSON 로그 필터링
- 네트워크 인터페이스 및 방화벽 문제 해결

단순히 보안 프로그램을 설치하는 것뿐만 아니라, 직접 탐지 규칙을 작성하고 테스트 트래픽을 발생시켜 경고를 확인하는 전체 과정을 실습하였다.

또한 탐지되지 않는 상황에서 네트워크 구성과 명령어 실행 환경을 점검하며 문제를 해결하는 경험을 쌓았다.
