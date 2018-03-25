/****************************************************************************
**
** Copyright (C) 2012 Denis Shienkov <denis.shienkov@gmail.com>
** Copyright (C) 2012 Laszlo Papp <lpapp@kde.org>
** Contact: https://www.qt.io/licensing/
**
** This file is part of the QtSerialPort module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "settingsdialog.h"

#include <QTextStream>
#include <QDateTime>
#include <QFileDialog>
#include <QFile>
#include <QLabel>
#include <QMessageBox>
#include <QDebug>

QString stroka;
QString filedir;

//! [0]
MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    m_ui(new Ui::MainWindow),
    m_status(new QLabel),
    m_settings(new SettingsDialog),
    m_filedial(new QFileDialog),
//! [1]
    m_serial(new QSerialPort(this))
//! [1]
{
//! [0]
    m_ui->setupUi(this);
    m_ui->actionConnect->setEnabled(true);
    m_ui->actionDisconnect->setEnabled(false);
    m_ui->actionQuit->setEnabled(true);
    m_ui->actionConfigure->setEnabled(true);
    m_ui->actionStartData->setEnabled(false);
    m_ui->actionStopData->setEnabled(false);
    m_ui->statusBar->addWidget(m_status);

    filedir = QDir::currentPath();
    m_ui->label->setText("Путь к файлам: " + filedir.toUtf8() + "/");

    initActionsConnections();

    connect(m_serial, &QSerialPort::errorOccurred, this, &MainWindow::handleError);

//! [2]
    connect(m_serial, &QSerialPort::readyRead, this, &MainWindow::readData);
}
//! [3]

MainWindow::~MainWindow()
{
    delete m_settings;
    delete m_ui;
}

//! [4]
void MainWindow::openSerialPort()
{
    const SettingsDialog::Settings p = m_settings->settings();
    m_serial->setPortName(p.name);
    m_serial->setBaudRate(p.baudRate);
    m_serial->setDataBits(p.dataBits);
    m_serial->setParity(p.parity);
    m_serial->setStopBits(p.stopBits);
    m_serial->setFlowControl(p.flowControl);
    if (m_serial->open(QIODevice::ReadWrite)) {
        m_ui->actionConnect->setEnabled(false);
        m_ui->actionDisconnect->setEnabled(true);
        m_ui->actionConfigure->setEnabled(false);
        m_ui->actionStartData->setEnabled(true);
        m_ui->actionStopData->setEnabled(false);
        showStatusMessage(tr("Подключено %1 : %2, %3, %4, %5, %6")
                          .arg(p.name).arg(p.stringBaudRate).arg(p.stringDataBits)
                          .arg(p.stringParity).arg(p.stringStopBits).arg(p.stringFlowControl));
        m_serial->clear();
    } else {
        QMessageBox::critical(this, tr("Ошибка"), m_serial->errorString());

        showStatusMessage(tr("Ошибка подключения"));
    }
}
//! [4]

//! [5]
void MainWindow::closeSerialPort()
{
    if (m_serial->isOpen())
        m_serial->close();
    m_ui->actionConnect->setEnabled(true);
    m_ui->actionDisconnect->setEnabled(false);
    m_ui->actionConfigure->setEnabled(true);
    m_ui->actionStartData->setEnabled(false);
    m_ui->actionStopData->setEnabled(false);
    showStatusMessage(tr("Отключено"));
}

void MainWindow::saveToFile()
{
    if( m_ui->lineEdit->text().isEmpty() )
    {
        m_ui->lineEdit->setText(QDateTime::currentDateTime().toString("yyyy-MM-dd_HH-mm-ss") + ".txt");
    }
    QFile file(filedir.toUtf8() + "/" + m_ui->lineEdit->text());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return;

    QTextStream out(&file);
    out << m_ui->textEdit->toPlainText();
    file.flush();
    file.close();
    //showStatusMessage(tr("Сохранено"));
}
//! [5]

void MainWindow::writeData(const QByteArray &data)
{
    m_serial->write(data);
}
//! [6]

//! [7]
void MainWindow::readData()
{
    const QByteArray data = m_serial->readAll();
    stroka.append(data);
    if (stroka.endsWith("\n"))
    {
        if (stroka.endsWith("\r\n"))
        {
            stroka.chop(2);
        } else {
            stroka.chop(1);
        }
        m_ui->textEdit->append(stroka);
        stroka.clear();
    }
    //m_console->putData(data);

}
//! [7]

//! [8]
void MainWindow::handleError(QSerialPort::SerialPortError error)
{
    if (error == QSerialPort::ResourceError) {
        QMessageBox::critical(this, tr("Критическая ошибка"), m_serial->errorString());
        closeSerialPort();
    }
}
//! [8]
void MainWindow::openFile()
{
    filedir =  m_filedial->getExistingDirectory(
              this,
              "Выбрать папку",
              "/home/user",
              QFileDialog::ShowDirsOnly);
    if( !filedir.isNull() )
    {
        m_ui->label->setText("Путь к файлам: " + filedir.toUtf8() + "/");
    }
}

void MainWindow::initActionsConnections()
{
    connect(m_ui->actionConnect, &QAction::triggered, this, &MainWindow::openSerialPort);
    connect(m_ui->actionDisconnect, &QAction::triggered, this, &MainWindow::closeSerialPort);
    connect(m_ui->actionSave, &QAction::triggered, this, &MainWindow::saveToFile);
    connect(m_ui->actionQuit, &QAction::triggered, this, &MainWindow::close);
    connect(m_ui->actionConfigure, &QAction::triggered, m_settings, &SettingsDialog::show);
    connect(m_ui->actionSaveAs, &QAction::triggered, this, &MainWindow::openFile);
}

void MainWindow::showStatusMessage(const QString &message)
{
    m_status->setText(message);
}

void MainWindow::on_actionClear_triggered()
{
    m_ui->textEdit->clear();
    m_ui->label->setText("Путь к файлам: /home/user/");
    filedir = "/home/user";
}

void MainWindow::on_actionStartData_triggered()
{
    if (m_serial->isOpen())
    {
        m_ui->actionStartData->setEnabled(false);
        m_ui->actionStopData->setEnabled(true);
        MainWindow::writeData(QByteArray("b")); //begin of data from hx711
        showStatusMessage(tr("Пишем..."));
    }

}

void MainWindow::on_actionStopData_triggered()
{
    MainWindow::writeData(QByteArray("e"));//end of data from hx711
    m_ui->actionStartData->setEnabled(true);
    m_ui->actionStopData->setEnabled(false);
    showStatusMessage(tr("Ждем..."));
}
