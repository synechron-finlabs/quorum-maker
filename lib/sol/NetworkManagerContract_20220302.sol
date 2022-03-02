pragma solidity^0.5.0;
contract NetworkManagerContract {

    uint nodeCounter;

    struct NodeDetails {
        string nodeName;
        string role;
        string publickey;
        string enode;
        string ip;
        string id;
    }

    mapping (string => NodeDetails)nodes;
    string[] enodeList;

    event print(string nodeName, string role,string publickey, string enode, string ip, string id);

    function registerNode(string memory n, string memory r, string memory p, string memory e, string memory ip, string memory id) public {

        nodes[e].publickey = p;
        nodes[e].nodeName = n;
        nodes[e].role = r;
        nodes[e].ip = ip;
        nodes[e].id = id;
        enodeList.push(e);
        emit print(n, r, p, e, ip, id);

    }

    function getNodeDetails(uint16 _index) public view returns (string memory n, string memory r, string memory p, string memory ip, string memory e, string memory id, uint i) {
        NodeDetails memory nodeInfo = nodes[enodeList[_index]];
        return (
            nodeInfo.nodeName,
            nodeInfo.role,
            nodeInfo.publickey,
            nodeInfo.ip,
            enodeList[_index],
            nodeInfo.id,
            _index
        );
    }

    function getNodesCounter() public view  returns (uint) {
        return enodeList.length;
    }

    function updateNode(string memory n, string memory r, string memory p, string memory e, string memory ip, string memory id) public {

        nodes[e].publickey = p;
        nodes[e].nodeName = n;
        nodes[e].role = r;
        nodes[e].ip = ip;
        nodes[e].id = id;
        emit print(n, r, p, e, ip, id);
    }

    function getNodeList(uint16 i)  public  view   returns (string memory n, string memory r,string memory p,string memory ip,string memory e, string memory id) {

        NodeDetails memory nodeInfo = nodes[enodeList[i]];
        return (
            nodeInfo.nodeName,
            nodeInfo.role,
            nodeInfo.publickey,
	        nodeInfo.ip,
            enodeList[i],
            nodeInfo.id
        );
    }

    function removeNode(uint index, string memory e) public {

        if (index < 0 || index >= enodeList.length) return;
        if ((keccak256(abi.encodePacked((enodeList[index]))) != keccak256(abi.encodePacked((e))))) return;
        delete enodeList[index];

        for (uint i = index; i<enodeList.length-1; i++){
            enodeList[i] = enodeList[i+1];
        }
        delete enodeList[enodeList.length-1];
        enodeList.length--;
    }
}
