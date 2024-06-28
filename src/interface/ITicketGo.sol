interface ITicketGo {
    struct Concert {
        uint256 concertId;
        address concertOwner;
        string concertName;
        string singerName;
        uint256 startSaleTime;
        uint256 endSaleTime;
        uint256 showTime;
        uint256 totalBalance;
        Area[] areas;
        // mapping(string areaName => Area) areas;
        bool withdrawed;
    }

    struct Area {
        string areaName;
        uint256 seats;
        uint256 price;
    }

    struct BuyerInfo {
        address audienceAddress;
        uint256 concertId;
        string credential;
        string areaName;
        uint256 amount;
        bool winning;
    }



    event EventAddConcert(uint256 indexed concertId, Concert concert);
    event EventAudienceBuyInfo(
        address indexed audienceAddress,
        BuyerInfo buyerInfo
    );
    event EventConcertBought(
        uint256 indexed concertId,
        string indexed areaName,
        address audienceAddress
    );
    event EventAudienceCanceled(
        address indexed audienceAddress,
        BuyerInfo buyerInfo
    );
    event AreaBookingSelected(
        uint256 indexed concertId,
        string concertName,
        uint256[] selectedBookingAddress
    );
    event ConcertSelected(uint256 indexed concertId);
    event EventConcertCancelBought(
        uint256 indexed concertId,
        string indexed areaName,
        address audienceAddress
    );
    event EventDispense(address indexed audienceAddress, BuyerInfo buyerInfo);
    event EventRefund(
        address indexed audienceAddress,
        bool isSuccessFul,
        BuyerInfo buyerInfo
    );
    event EventWithdraw(
        uint256 indexed concertId,
        bool singerSuccess,
        address singerAddress,
        uint256 singerAmount,
        bool operatorSuccess,
        address operatorAddress,
        uint256 operatorAmount
    );
}