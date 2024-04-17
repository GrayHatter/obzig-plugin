#include <QtWidgets>

//#include "qtdockwidget.h"
#include "qtdockwidget.moc"


QDockWidget* ZigQt::createDock(QWidget *parent) {
    QDockWidget *dock = new QDockWidget(tr("Sway-Focus"), parent);
    return dock;
}

extern "C" {

QDockWidget* createDock(QWidget *parent) {
    auto zqt = new ZigQt();

    QDockWidget *dock = zqt->createDock(parent);
	return dock;
}

}

