module.exports = (xo) => {
  xo.on('menu', (menu) => {
    return menu.filter(item => {
      if (item.to === '/hub/templates') return false;
      if (item.subMenu) {
        item.subMenu = item.subMenu.filter(subItem =>
          !subItem.to.startsWith('/hub/')
        );
      }
      return true;
    });
  });
};
