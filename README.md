<img width="512" height="244" alt="Image" src="https://github.com/user-attachments/assets/f531dec5-3081-4887-911c-3b817a4cf5d5" />

# 프로젝트 소개
> 정보 과잉으로 코스 선택이 어려운 상황에서, 20~30대를 위한 코스를 추천하고 토론하는  코스 추천 커뮤니티

# 개발 기간
> 2025.10.29 ~ 2025.11.22
# 사용 기술
    1. API
        - Naver Map
        - Kakao Map
    
    2. Database
        - Supabase
    
    3. Library
        - cupertino_icons
        - image_picker
        - supabase_flutter
        - provider
        - go_router
        - url_launcher
        - flutter_naver_map
        - dio
        - http
        - google_sign_in
        - supabase_progress_uploads
        - flutter_native_splash
        - shared_preferences
        - cached_network_image

# 아키텍처
<img width="797" height="383" alt="Image" src="https://github.com/user-attachments/assets/e513799f-1b43-4b8e-b8fc-cf85d604d4b9" />

# 주요 기능 및 화면
### 1. 인증
- Supabase와 Google auth를 사용한 소셜로그
### 2. 홈
- 기본 코스 목록 제공
- 코스 제목, 이미지, 태그, 좋아요와 댓글 표시
- 지역선택 드롭다운 메뉴 제공
- 여러개 선택가능한 태그 목록 제공
- 랜덤버튼으로 코스 추천기능 제공
- 지역과 태그 선택시 해당되는 코스목록만 보이게 표시
### 3. 코스 작성
- 네이버,카카오 지도 기반의 주소,매장 검색 시스템 제공
- 검색시 해당 장소에 마커로 표시
- 촬영이나 앨범에서 고른 이미지 업로드기능 제공
- 사용자의 편의를 위해 제목과 설명에 텍스트 제한을 
- 임시저장 기능 제공, 임시저장 여부에 따라 이어쓰기, 새로쓰기 모드 제공
- 업로드시, 각 세트의 주소검색, 설명, 태그 부분이 비어있다면 업로드 제한됨
### 4. 코스 상세
- 지도위의 마커에 순서를 부여해 직관적인 데이터 제공
- 각각의 세트와 마커를 클릭시 해당 마커나 세트로 이동해서 보여주는 양방향 이동기능 제공
- 좋아요, 댓글 기능을 제공, 사용자들의 참여를 유도
- 신고 기능을 제공, 컨텐츠의 품질관리가 가능함
### 5. 코스 추천
- 사용자가 좋아요를 누른 코스의 존재여부를 판단해 2가지 경우로 기능 제공
- 사용자의 활동 로그를 기반으로 코스의 점수(퍼센트)를 매겨 상위5개중 1개를 랜덤 제공
- 기존 코스 상세 화면에 퍼센트와 추천사유를 포함해서 표시
### 6. 프로필 화면
- 닉네임 변경
- 작성한 코스 화면
- 앱의 전체 테마 정하기(라이트,다크,핸드폰테마)
- 약관확인
- 로그아웃
- 회원탈퇴
# 화면
| 로그인 화면 | 약관동의 화면 | 회원가입 화면 |
| --- | --- | --- |
| <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/4d99a82a-4115-4168-b109-4389208f483f" /> | <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/e8b3aefa-1ced-4d15-854a-5c3fd9988a17" /> | <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/24b1f332-c3bf-4137-a8e6-4d74b72dbacf" /> |
| 홈 화면 | 코스작성 화면 | 코스작성 화면 |
| <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/1c73d026-611e-461b-b985-2fba927bc7b3" /> | <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/b84c0da7-0ee3-46f8-9e8e-1b0848543930" /> | <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/d7d0b027-f837-48a6-9b43-2237d318dc75" /> |
| 알림 화면 | 코스상세 화면 | 프로필 화면 |
| <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/8b8e8656-62d3-427c-a764-9bafa685898f" /> | <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/05bbf1b9-8e13-4c90-b9da-55d02433cdc7" /> | <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/311d899b-828c-4cf4-9ac0-14b52ace4b87" /> |
| 테마변경 화면 | 
| <img width="250" height="800" alt="Image" src="https://github.com/user-attachments/assets/81b082e0-061d-41e1-b069-7794a5c80563" /> |

# 시연 영상 (넣을지 말지 고민)
동영상 링크

# 저작권(출처)
- Naver Maps API
- Naver_Map_sdk

# 팀원 소개

| 팀장 | 부팀장 | 팀원 | 팀원 |
| :-: | :--: | :-: | :-: |
| <img width="140" height="140" alt="Image" src="https://github.com/user-attachments/assets/93d32ea6-17e6-4bdd-8767-cb5f0c2a9233" /> | <img width="140" height="140" alt="Image" src="https://github.com/user-attachments/assets/fb7da56a-2946-4931-a0b8-c36f328cbc6c" /> |  <img width="140" height="140" alt="Image" src="https://github.com/user-attachments/assets/3b370bd6-d490-4882-92f6-d333fb7ef7a0" /> | <img width="140" height="140" alt="Image" src="https://github.com/user-attachments/assets/06193817-4aec-4562-abed-fad9e370a7db" /> |
| [신강현](https://github.com/ENKH123) | [김재현](https://github.com/kimdzhekhon) | [권영진](https://github.com/0jhin) | [엄수빈](https://github.com/EomSB)

| 팀원 | 역할 |
| :---: | :--- |
| **신강현** | - **Course** <br>&emsp;&emsp;- **코스 작성** 화면 UI 및 기능 개발<br>&emsp;&emsp;- **임시저장** 기능 개발<br>&emsp;&emsp;- **코스 수정 · 코스 삭제** 기능 개발<br>&emsp;&emsp;- **내가 작성한 코스** 화면 UI 및 기능 개발<br>&emsp;&emsp;- **저장(좋아요)한 코스** 화면 UI 및 기능 개발<br>&emsp;&emsp;- **네이버 지도 SDK · 카카오 지역 API** 기반 **마커** 기능 개발<br><br>- **Home** <br>&emsp;&emsp;- **홈** 화면 UI 및 기능 개발<br>&emsp;&emsp;- **태그 · 지역** 기반 **필터링** 기능 개발  |
| **김재현** |- **Course** <br>&emsp;&emsp;- **코스 디테일** 화면 UI 및 기능 개발<br>&emsp;&emsp;- **코스 좋아요 · 취소** 기능 개발<br>&emsp;&emsp;- **코스 댓글 추가 · 삭제** 기능 개발<br>&emsp;&emsp;- **마커 순서 · 경로 표시, 반응형 지도** 기능 개발<br><br>- **Recommend** <br>&emsp;&emsp;- **추천 로직** 기능 개발<br><br>- **Report**<br>&emsp;&emsp;- **신고** 화면 UI 및 기능 개발<br><br>- **Terms**<br>&emsp;&emsp;- **약관 확인** 팝업 UI 및 기능 개발   |
| **권영진** | **Authentication** <br>&emsp;&emsp;- **로그인** 화면 UI 및 기능 개발<br>&emsp;&emsp;&emsp;&emsp;- 구글 로그인 OAuth<br>&emsp;&emsp;- **회원가입 · 약관동의** 화면 UI 및 기능 개발<br>&emsp;&emsp;- **로그아웃 · 회원탈퇴** 기능 개발<br><br>- **Alert** <br>&emsp;&emsp;- 알림 화면 UI 및 인앱 **실시간 알림** 기능 개발<br><br>- **Onboarding**<br>&emsp;&emsp;- **온보딩** 화면 UI 및 기능 개발<br><br>- **Other**<br>&emsp;&emsp;- 화면별, 기능별 **버그 · 누락 · 수정 · 추가** 사항 점검   |
| **엄수빈** |  **Theme** <br>&emsp;&emsp;- 앱의 **라이트모드 · 다크모드 · 기기모드** 테마 적용 및 **적용사항 유지** 기능 개발<br>&emsp;&emsp;- 프로젝트 **폰트** 변경<br><br>- **Profile** <br>&emsp;&emsp;- **프로필** 화면 UI 및 기능 개발<br>&emsp;&emsp;- **프로필 수정** 화면 UI 및 기능 개발<br><br>- **Other**<br>&emsp;&emsp;- 전반적인 UI **디자인** 및 **컬러 코드** 적용   |





