// Guard against clickjacking
if (window.self === window.top) {
    var antiClickjack = document.getElementById("antiClickjack");
    antiClickjack.parentNode.removeChild(antiClickjack);
} else {
    window.top.location = window.self.location;
}
